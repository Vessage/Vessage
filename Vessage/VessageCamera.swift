//  VessageCamera.swift
//
//  Vessage
//
//  Created by AlexChow on 16/3/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import AVFoundation
import YUCIHighPassSkinSmoothing

//MARK:VessageCamera Delegate
@objc protocol VessageCameraDelegate{
    @objc optional func vessageCameraVideoSaved(videoSavedUrl video:URL)
    @objc optional func vessageCameraSaveVideoError(saveVideoError msg:String?)
    @objc optional func vessageCameraImage(_ image:UIImage)
    @objc optional func vessageCameraReady()
    @objc optional func vessageCameraSessionClosed()
    @objc optional func vessageCameraDidStartRecord()
    @objc optional func vessageCameraDidStopRecord()
}

//MARK:VessageCamera
class VessageCamera:NSObject,AVCaptureVideoDataOutputSampleBufferDelegate , AVCaptureMetadataOutputObjectsDelegate,AVCaptureAudioDataOutputSampleBufferDelegate {
    
    weak var delegate:VessageCameraDelegate?
    var isRecordVideo:Bool = true
    fileprivate(set) var cameraInited = false
    var cameraRunning:Bool{
        return captureSession?.isRunning ?? false
    }
    fileprivate var rootViewController:UIViewController!
    fileprivate var view:UIView!
    fileprivate var captureSession: AVCaptureSession!
    fileprivate var previewLayer: CALayer!
    fileprivate var filter: CIFilter!
    fileprivate lazy var context: CIContext = {
        let eaglContext = EAGLContext(api: EAGLRenderingAPI.openGLES2)
        let options = [kCIContextWorkingColorSpace : NSNull()]
        return CIContext(eaglContext: eaglContext!, options: options)
    }()
    fileprivate var ciImage: CIImage!
    
    // 标记人脸
    var enableFaceMark = false
    fileprivate var faceLayer: CALayer?
    fileprivate var faceObject: AVMetadataFaceObject?
    fileprivate(set) var detectedFaces = false
    
    fileprivate var assetWriter: AVAssetWriter?
    fileprivate var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    fileprivate var assetWriterAudioInput:AVAssetWriterInput!
    fileprivate var isWriting = false{
        didSet{
            if oldValue != isWriting{
                if isWriting{
                    if let handler = self.delegate?.vessageCameraDidStartRecord{
                        handler()
                    }
                }else{
                    if let handler = self.delegate?.vessageCameraDidStopRecord{
                        handler()
                    }
                }
            }
        }
    }
    fileprivate var currentSampleTime: CMTime?
    fileprivate var currentVideoDimensions: CMVideoDimensions?
    
    fileprivate var audioCompressionSettings:[String:AnyObject]?
    
    func initCamera(_ rootViewController:UIViewController,previewView:UIView){
        self.rootViewController = rootViewController
        self.view = previewView
        previewLayer = CALayer()
        previewLayer.contentsGravity = kCAGravityResizeAspectFill
        previewLayer.anchorPoint = CGPoint.zero
        previewLayer.bounds = view.bounds
        previewLayer.backgroundColor = UIColor.black.cgColor
        self.view.layer.insertSublayer(previewLayer, at: 0)
        if TARGET_IPHONE_SIMULATOR == Int32("1") {
            self.rootViewController.playToast("Simulator No Camera");
            self.previewLayer.isHidden = true
            return
        } else {
            setupCaptureSession()
        }
        initFilter()
        cameraInited = true
    }
    
    deinit{
        #if DEBUG
            print("Deinited:\(self.description)")
        #endif
    }
    
    fileprivate func initFilter(){
        #if RELEASE
        filter = CIFilter(name: "YUCIHighPassSkinSmoothing",withInputParameters: ["inputAmount":0.7])
        #endif
    }
    
    //MARK: notification
    fileprivate func initNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(VessageCamera.didSessionStartRunning(_:)), name: NSNotification.Name.AVCaptureSessionDidStartRunning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VessageCamera.didSessionStopRunning(_:)), name: NSNotification.Name.AVCaptureSessionDidStopRunning, object: nil)
    }
    
    func didSessionStartRunning(_ a:Notification){
        if let handler = delegate?.vessageCameraReady{
            handler()
        }
    }
    
    func didSessionStopRunning(_ a:Notification){
        if let handler = delegate?.vessageCameraSessionClosed{
            handler()
        }
    }
    
    func viewWillTransitionToSize(_ size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        previewLayer.bounds.size = size
    }
    
    fileprivate func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = isRecordVideo ? AVCaptureSessionPresetMedium : AVCaptureSessionPresetPhoto
        setupVideoSession()
        setupAudioSession()
        setupFaceDetect()
        captureSession.commitConfiguration()
    }
    
    fileprivate func setupVideoSession(){
        let queue = DispatchQueue(label: "VMCQueue", attributes: [])
        
        //视频
        let captureDevice = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).filter{($0 as AnyObject).position == AVCaptureDevicePosition.front}.first as! AVCaptureDevice
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice)
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        //MARK: 调整方向为自然方向
        let con = dataOutput.connection(withMediaType: AVMediaTypeVideo)
        con?.isVideoMirrored = true
        con?.videoOrientation = .landscapeRight
    }
    
    fileprivate func setupAudioSession(){
        if !isRecordVideo{
            return
        }
        
        //声音
        let captureAudioDev = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        let audioInput = try! AVCaptureDeviceInput(device: captureAudioDev)
        if captureSession.canAddInput(audioInput){
            captureSession.addInput(audioInput)
        }
        
        let audioOutput = AVCaptureAudioDataOutput()
        if captureSession.canAddOutput(audioOutput){
            captureSession.addOutput(audioOutput)
        }
        
        //音频与视频的队列需要分开，否则加入滤镜后没有声音输出
        let aqueue = DispatchQueue(label: "VMCAQueue", attributes: [])
        audioOutput.setSampleBufferDelegate(self, queue: aqueue)
    }
    
    fileprivate func setupFaceDetect(){
        // 为了检测人脸
        if enableFaceMark{
            let metadataOutput = AVCaptureMetadataOutput()
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
            }
        }
    }
    
    func openCamera() {
        if cameraInited == true && !cameraRunning{
            initNotification()
            previewLayer.bounds = view.bounds
            captureSession.startRunning()
        }
    }
    
    func closeCamera(){
        if cameraInited == true{
            cameraInited = false
            self.rootViewController = nil
            captureSession?.stopRunning()
            captureSession = nil
            NotificationCenter.default.removeObserver(self)
        }
        
    }
    
    // MARK: - Video Records
    @discardableResult
    func startRecord()->Bool{
        if isWriting == false{
            createWriter()
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: currentSampleTime!)
            isWriting = true
            return true
        }
        return false
    }
    
    func takePicture() {
        if ciImage == nil || isWriting {
            return
        }
        faceLayer?.isHidden = true
        captureSession.stopRunning()
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        let image = UIImage(cgImage: cgImage!)
        if let saveHandler = self.delegate?.vessageCameraImage{
            saveHandler(image)
        }
    }
    
    func resumeCaptureSession(){
        detectedFaces = false
        captureSession?.startRunning()
    }
    
    func pauseCaptureSession(){
        captureSession?.stopRunning()
    }
    
    func saveRecordedVideo(){
        if isWriting {
            self.isWriting = false
            assetWriterPixelBufferInput = nil
            if let saveHandler = self.delegate?.vessageCameraVideoSaved{
                assetWriter?.finishWriting(completionHandler: { () -> Void in
                    let avAssets = AVURLAsset(url: self.tmpFilmURL)
                    let exportSession = AVAssetExportSession(asset: avAssets, presetName: AVAssetExportPresetMediumQuality)
                    self.checkForAndDeleteFile(self.tmpCompressedFilmURL)
                    exportSession?.outputURL = self.tmpCompressedFilmURL
                    exportSession?.outputFileType = AVFileTypeMPEG4
                    exportSession?.shouldOptimizeForNetworkUse = true
                    exportSession?.exportAsynchronously(completionHandler: { () -> Void in
                        saveHandler(self.tmpCompressedFilmURL)
                    })
                })
            }
        }else{
            assetWriter?.cancelWriting()
        }
    }
    
    func cancelRecord(){
        if isWriting{
            assetWriterPixelBufferInput = nil
            assetWriter?.cancelWriting()
            isWriting = false
        }
    }
    
    var tmpFilmURL:URL {
        let tempDir = NSTemporaryDirectory()
        let url = URL(fileURLWithPath: tempDir).appendingPathComponent("tmpVessage.mp4")
        return url
    }
    
    var tmpCompressedFilmURL:URL{
        let tempDir = NSTemporaryDirectory()
        let url = URL(fileURLWithPath: tempDir).appendingPathComponent("tmpVessageC.mp4")
        return url
    }
    
    func checkForAndDeleteFile(_ url:URL) {
        let fm = FileManager.default
        let exist = fm.fileExists(atPath: url.path)
        
        if exist {
            do {
                try fm.removeItem(at: url)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    func createWriter() {
        self.checkForAndDeleteFile(self.tmpFilmURL)
        
        do {
            assetWriter = try AVAssetWriter(outputURL: tmpFilmURL, fileType: AVFileTypeMPEG4)
        } catch let error as NSError {
            print("创建writer失败")
            print(error.localizedDescription)
            return
        }
        
        let width = currentVideoDimensions!.width
        let height = currentVideoDimensions!.height
        let outputSettings = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : Int(width),
            AVVideoHeightKey : Int(height)
        ] as [String : Any]
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI / 2.0))
        
        let sourcePixelBufferAttributesDictionary = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey) : Int(width),
            String(kCVPixelBufferHeightKey) : Int(height),
            String(kCVPixelFormatOpenGLESCompatibility) : kCFBooleanTrue
        ] as [String : Any]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if assetWriter!.canAdd(assetWriterVideoInput) {
            assetWriter!.add(assetWriterVideoInput)
        } else {
            print("不能添加视频writer的input \(assetWriterVideoInput)")
        }
        
        
        //声音writer
        if audioCompressionSettings == nil{
            self.audioCompressionSettings = [
                AVFormatIDKey : NSNumber(value: kAudioFormatMPEG4AAC as UInt32),
                AVNumberOfChannelsKey : NSNumber(value: 1 as UInt32),
                AVSampleRateKey :  NSNumber(value: 44100 as Double),
                AVEncoderBitRateKey : NSNumber(value: 64000 as Int32)
            ]
        }
        self.assetWriterAudioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioCompressionSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        if assetWriter!.canAdd(assetWriterAudioInput){
            assetWriter!.add(assetWriterAudioInput)
        }else{
            print("不能添加音频writer的input \(assetWriterAudioInput)")
        }
    }
    
    // MARK: - AVCaptureVideo/AudioDataOutputSampleBufferDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!,didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,from connection: AVCaptureConnection!) {
        autoreleasepool {
            if captureOutput is AVCaptureVideoDataOutput{
                if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer){
                    writeVideoMedia(sampleBuffer,imageBuffer: imageBuffer)
                }
            }else if isWriting{
                self.writeAudioMedia(sampleBuffer)
            }else if isRecordVideo{
                setAudioCompressSetting(sampleBuffer)
            }
        }
    }
    
    fileprivate func setAudioCompressSetting(_ sampleBuffer: CMSampleBuffer!){
        if self.audioCompressionSettings != nil{
            return
        }
        if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer){
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
            if (asbd != nil) {
                let channels = asbd?.pointee.mChannelsPerFrame
                let sampleRate = asbd?.pointee.mSampleRate
                self.audioCompressionSettings = [
                    AVFormatIDKey : NSNumber(value: kAudioFormatMPEG4AAC as UInt32),
                    AVNumberOfChannelsKey : NSNumber(value: channels! as UInt32),
                    AVSampleRateKey :  NSNumber(value: sampleRate! as Double),
                    AVEncoderBitRateKey : NSNumber(value: 64000 as Int32)
                ]
            }else{
                print("No AudioFormatDescription")
            }
        }
    }
    
    fileprivate func writeAudioMedia(_ sampleBuffer:CMSampleBuffer){
        if self.assetWriterAudioInput.isReadyForMoreMediaData{
            self.assetWriterAudioInput.append(sampleBuffer)
        }
    }
    
    fileprivate func writeVideoMedia(_ sampleBuffer:CMSampleBuffer,imageBuffer:CVImageBuffer){
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        var outputImage = CIImage(cvPixelBuffer: imageBuffer)
        
        if self.filter != nil {
            self.filter.setValue(outputImage, forKey: kCIInputImageKey)
            outputImage = self.filter.outputImage!
        }
        
        // 录制视频的处理
        if self.isWriting {
            if self.assetWriterPixelBufferInput?.assetWriterInput.isReadyForMoreMediaData == true {
                var newPixelBuffer: CVPixelBuffer? = nil
                
                CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput!.pixelBufferPool!, &newPixelBuffer)
                
                self.context.render(outputImage, to: newPixelBuffer!, bounds: outputImage.extent, colorSpace: nil)
                
                let success = self.assetWriterPixelBufferInput?.append(newPixelBuffer!, withPresentationTime: self.currentSampleTime!)
                
                if success == false {
                    print("Pixel Buffer没有附加成功")
                }
            }
        }
        
        let orientation = UIDevice.current.orientation
        var t: CGAffineTransform!
        if orientation == UIDeviceOrientation.portrait {
            t = CGAffineTransform(rotationAngle: CGFloat(-M_PI / 2.0))
        } else if orientation == UIDeviceOrientation.portraitUpsideDown {
            t = CGAffineTransform(rotationAngle: CGFloat(M_PI / 2.0))
        } else if (orientation == UIDeviceOrientation.landscapeRight) {
            t = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        } else {
            t = CGAffineTransform(rotationAngle: 0)
        }
        outputImage = outputImage.applying(t)
        
        let cgImage = self.context.createCGImage(outputImage, from: outputImage.extent)
        self.ciImage = outputImage
        
        DispatchQueue.main.sync(execute: {
            self.previewLayer.contents = cgImage
        })
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        //识别到的第一张脸
        if let faceObject = metadataObjects?.first as? AVMetadataFaceObject{
            detectedFaces = true
            if faceLayer == nil {
                faceLayer = CALayer()
                faceLayer?.borderColor = UIColor.red.cgColor
                faceLayer?.borderWidth = 1
                view.layer.addSublayer(faceLayer!)
            }
            let faceBounds = faceObject.bounds
            let viewSize = view.bounds.size
            
            faceLayer?.position = CGPoint(x: viewSize.width * (1 - faceBounds.origin.y - faceBounds.size.height / 2),
                                          y: viewSize.height * (faceBounds.origin.x + faceBounds.size.width / 2))
            
            faceLayer?.bounds.size = CGSize(width: faceBounds.size.height * viewSize.width,
                                            height: faceBounds.size.width * viewSize.height)
        }else if detectedFaces{
            detectedFaces = false
        }
        faceLayer?.isHidden = !detectedFaces
    }
}
