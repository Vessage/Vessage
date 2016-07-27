//  VessageCamera.swift
//
//  Vessage
//
//  Created by AlexChow on 16/3/7.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary
import YUCIHighPassSkinSmoothing

//MARK:VessageCamera Delegate
@objc protocol VessageCameraDelegate{
    optional func vessageCameraVideoSaved(videoSavedUrl video:NSURL)
    optional func vessageCameraSaveVideoError(saveVideoError msg:String?)
    optional func vessageCameraImage(image:UIImage)
    optional func vessageCameraReady()
    optional func vessageCameraSessionClosed()
    optional func vessageCameraDidStartRecord()
    optional func vessageCameraDidStopRecord()
}

//MARK:VessageCamera
class VessageCamera:NSObject,AVCaptureVideoDataOutputSampleBufferDelegate , AVCaptureMetadataOutputObjectsDelegate,AVCaptureAudioDataOutputSampleBufferDelegate {
    
    var delegate:VessageCameraDelegate?
    var isRecordVideo:Bool = true
    private(set) var cameraInited = false
    private var rootViewController:UIViewController!
    private var view:UIView!
    private var captureSession: AVCaptureSession!
    private var previewLayer: CALayer!
    private var filter: CIFilter!
    private lazy var context: CIContext = {
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        let options = [kCIContextWorkingColorSpace : NSNull()]
        return CIContext(EAGLContext: eaglContext, options: options)
    }()
    private var ciImage: CIImage!
    
    // 标记人脸
    var enableFaceMark = false
    private var faceLayer: CALayer?
    private var faceObject: AVMetadataFaceObject?
    private(set) var detectedFaces = false
    
    private var assetWriter: AVAssetWriter?
    private var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    private var assetWriterAudioInput:AVAssetWriterInput!
    private var isWriting = false{
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
    private var currentSampleTime: CMTime?
    private var currentVideoDimensions: CMVideoDimensions?
    
    private var audioCompressionSettings:[String:AnyObject]?
    
    func initCamera(rootViewController:UIViewController,previewView:UIView){
        self.rootViewController = rootViewController
        self.view = previewView
        self.rootViewController.view.addSubview(self.view)
        self.rootViewController.view.bringSubviewToFront(self.view)
        previewLayer = CALayer()
        previewLayer.anchorPoint = CGPointZero
        previewLayer.bounds = view.bounds
        self.view.layer.insertSublayer(previewLayer, atIndex: 0)
        if TARGET_IPHONE_SIMULATOR == Int32("1") {
            self.rootViewController.playToast("Simulator No Camera");
            return
        } else {
            setupCaptureSession()
        }
        initFilter()
        cameraInited = true
    }
    
    private func initFilter(){
        #if RELEASE
        filter = CIFilter(name: "YUCIHighPassSkinSmoothing",withInputParameters: ["inputAmount":0.7])
        #endif
    }
    
    //MARK: notification
    private func initNotification(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VessageCamera.didSessionStartRunning(_:)), name: AVCaptureSessionDidStartRunningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VessageCamera.didSessionStopRunning(_:)), name: AVCaptureSessionDidStopRunningNotification, object: nil)
    }
    
    func didSessionStartRunning(a:NSNotification){
        if let handler = delegate?.vessageCameraReady{
            handler()
        }
    }
    
    func didSessionStopRunning(a:NSNotification){
        if let handler = delegate?.vessageCameraSessionClosed{
            handler()
        }
    }
    
    func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        previewLayer.bounds.size = size
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = isRecordVideo ? AVCaptureSessionPresetMedium : AVCaptureSessionPresetPhoto
        setupVideoSession()
        setupAudioSession()
        setupFaceDetect()
        captureSession.commitConfiguration()
        
    }
    
    private func setupVideoSession(){
        let queue = dispatch_queue_create("VMCQueue", DISPATCH_QUEUE_SERIAL)
        
        //视频
        let captureDevice = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).filter{$0.position == AVCaptureDevicePosition.Front}.first as! AVCaptureDevice
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice)
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        //MARK: 调整方向为自然方向
        let con = dataOutput.connectionWithMediaType(AVMediaTypeVideo)
        con.videoMirrored = true
        con.videoOrientation = .Portrait
    }
    
    private func setupAudioSession(){
        if !isRecordVideo{
            return
        }
        
        //声音
        let captureAudioDev = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        let audioInput = try! AVCaptureDeviceInput(device: captureAudioDev)
        if captureSession.canAddInput(audioInput){
            captureSession.addInput(audioInput)
        }
        
        let audioOutput = AVCaptureAudioDataOutput()
        if captureSession.canAddOutput(audioOutput){
            captureSession.addOutput(audioOutput)
        }
        
        //音频与视频的队列需要分开，否则加入滤镜后没有声音输出
        let aqueue = dispatch_queue_create("VMCAQueue", DISPATCH_QUEUE_SERIAL)
        audioOutput.setSampleBufferDelegate(self, queue: aqueue)
    }
    
    private func setupFaceDetect(){
        // 为了检测人脸
        if enableFaceMark{
            let metadataOutput = AVCaptureMetadataOutput()
            metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
            }
        }
    }
    
    func openCamera() {
        if cameraInited == true{
            initNotification()
            captureSession.startRunning()
        }
    }
    
    func closeCamera(){
        if cameraInited == true{
            captureSession.stopRunning()
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }
    
    // MARK: - Video Records
    func startRecord()->Bool{
        if isWriting == false{
            createWriter()
            assetWriter?.startWriting()
            assetWriter?.startSessionAtSourceTime(currentSampleTime!)
            isWriting = true
            return true
        }
        return false
    }
    
    func takePicture() {
        if ciImage == nil || isWriting {
            return
        }
        faceLayer?.hidden = true
        let cgImage = context.createCGImage(ciImage, fromRect: ciImage.extent)
        let image = UIImage(CGImage: cgImage)
        if let saveHandler = self.delegate?.vessageCameraImage{
            saveHandler(image)
        }
    }
    
    func resumeCaptureSession(){
        detectedFaces = false
        captureSession.startRunning()
    }
    
    func pauseCaptureSession(){
        captureSession.stopRunning()
    }
    
    func saveRecordedVideo(){
        if isWriting {
            self.isWriting = false
            assetWriterPixelBufferInput = nil
            if let saveHandler = self.delegate?.vessageCameraVideoSaved{
                assetWriter?.finishWritingWithCompletionHandler({ () -> Void in
                    let avAssets = AVURLAsset(URL: self.tmpFilmURL)
                    let exportSession = AVAssetExportSession(asset: avAssets, presetName: AVAssetExportPresetMediumQuality)
                    self.checkForAndDeleteFile(self.tmpCompressedFilmURL)
                    exportSession?.outputURL = self.tmpCompressedFilmURL
                    exportSession?.outputFileType = AVFileTypeMPEG4
                    exportSession?.shouldOptimizeForNetworkUse = true
                    exportSession?.exportAsynchronouslyWithCompletionHandler({ () -> Void in
                        saveHandler(videoSavedUrl: self.tmpCompressedFilmURL)
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
    
    var tmpFilmURL:NSURL {
        let tempDir = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: tempDir).URLByAppendingPathComponent("tmpVessage.mp4")
        return url
    }
    
    var tmpCompressedFilmURL:NSURL{
        let tempDir = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: tempDir).URLByAppendingPathComponent("tmpVessageC.mp4")
        return url
    }
    
    func checkForAndDeleteFile(url:NSURL) {
        let fm = NSFileManager.defaultManager()
        let exist = fm.fileExistsAtPath(url.path!)
        
        if exist {
            do {
                try fm.removeItemAtURL(url)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    func createWriter() {
        self.checkForAndDeleteFile(self.tmpFilmURL)
        
        do {
            assetWriter = try AVAssetWriter(URL: tmpFilmURL, fileType: AVFileTypeMPEG4)
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
        ]
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings as? [String : AnyObject])
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        //assetWriterVideoInput.transform = CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0))
        
        let sourcePixelBufferAttributesDictionary = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey) : Int(width),
            String(kCVPixelBufferHeightKey) : Int(height),
            String(kCVPixelFormatOpenGLESCompatibility) : kCFBooleanTrue
        ]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if assetWriter!.canAddInput(assetWriterVideoInput) {
            assetWriter!.addInput(assetWriterVideoInput)
        } else {
            print("不能添加视频writer的input \(assetWriterVideoInput)")
        }
        
        
        //声音writer
        if audioCompressionSettings == nil{
            self.audioCompressionSettings = [
                AVFormatIDKey : NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
                AVNumberOfChannelsKey : NSNumber(unsignedInt: 1),
                AVSampleRateKey :  NSNumber(double: 44100),
                AVEncoderBitRateKey : NSNumber(int: 64000)
            ]
        }
        self.assetWriterAudioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioCompressionSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        if assetWriter!.canAddInput(assetWriterAudioInput){
            assetWriter!.addInput(assetWriterAudioInput)
        }else{
            print("不能添加音频writer的input \(assetWriterAudioInput)")
        }
    }
    
    // MARK: - AVCaptureVideo/AudioDataOutputSampleBufferDelegate
    func captureOutput(captureOutput: AVCaptureOutput!,didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,fromConnection connection: AVCaptureConnection!) {
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
    
    private func setAudioCompressSetting(sampleBuffer: CMSampleBuffer!){
        if self.audioCompressionSettings != nil{
            return
        }
        if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer){
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
            if (asbd != nil) {
                let channels = asbd.memory.mChannelsPerFrame
                let sampleRate = asbd.memory.mSampleRate
                self.audioCompressionSettings = [
                    AVFormatIDKey : NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
                    AVNumberOfChannelsKey : NSNumber(unsignedInt: channels),
                    AVSampleRateKey :  NSNumber(double: sampleRate),
                    AVEncoderBitRateKey : NSNumber(int: 64000)
                ]
            }else{
                print("No AudioFormatDescription")
            }
        }
    }
    
    private func writeAudioMedia(sampleBuffer:CMSampleBufferRef){
        if self.assetWriterAudioInput.readyForMoreMediaData{
            self.assetWriterAudioInput.appendSampleBuffer(sampleBuffer)
        }
    }
    
    private func writeVideoMedia(sampleBuffer:CMSampleBuffer,imageBuffer:CVImageBuffer){
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        var outputImage = CIImage(CVPixelBuffer: imageBuffer)
        
        if self.filter != nil {
            self.filter.setValue(outputImage, forKey: kCIInputImageKey)
            outputImage = self.filter.outputImage!
        }
        
        // 录制视频的处理
        if self.isWriting {
            if self.assetWriterPixelBufferInput?.assetWriterInput.readyForMoreMediaData == true {
                var newPixelBuffer: CVPixelBuffer? = nil
                
                CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput!.pixelBufferPool!, &newPixelBuffer)
                
                self.context.render(outputImage, toCVPixelBuffer: newPixelBuffer!, bounds: outputImage.extent, colorSpace: nil)
                
                let success = self.assetWriterPixelBufferInput?.appendPixelBuffer(newPixelBuffer!, withPresentationTime: self.currentSampleTime!)
                
                if success == false {
                    print("Pixel Buffer没有附加成功")
                }
            }
        }
        
        let cgImage = self.context.createCGImage(outputImage, fromRect: outputImage.extent)
        self.ciImage = outputImage
        
        dispatch_sync(dispatch_get_main_queue(), {
            self.previewLayer.contents = cgImage
        })
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        //识别到的第一张脸
        if let faceObject = metadataObjects?.first as? AVMetadataFaceObject{
            detectedFaces = true
            if faceLayer == nil {
                faceLayer = CALayer()
                faceLayer?.borderColor = UIColor.redColor().CGColor
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
        faceLayer?.hidden = !detectedFaces
    }
}