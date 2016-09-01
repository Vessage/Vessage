//
//  SoundService.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/29.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreLocation

class LocationService:NSNotificationCenter,ServiceProtocol,CLLocationManagerDelegate
{
    @objc static var ServiceName:String{return "Location Service"}
    static let hereUpdated = "hereUpdated"
    private var locationManager:CLLocationManager!
    @objc func appStartInit(appName:String) {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 1000.0
        self.locationManager.startUpdatingLocation()
    }
    
    func userLoginInit(userId: String) {
        self.setServiceReady()
    }
    
    var isLocationServiceEnabled:Bool{
        return CLLocationManager.locationServicesEnabled()
    }
    
    func refreshHere()
    {
        self.locationManager.startUpdatingLocation()
    }
    
    private(set) var here:CLLocation!
    
    var hereLocationString:String!{
        if let h = here{
            return "{ \"type\": \"Point\", \"coordinates\": [\(h.coordinate.longitude), \(h.coordinate.latitude)] }"
        }
        return nil
    }
    
    //MARK: CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        here = newLocation
        self.postNotificationName(LocationService.hereUpdated, object: self)
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
    }
}

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getLocationService() -> LocationService {
        return ServiceContainer.getService(LocationService)
    }
}