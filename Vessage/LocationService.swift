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
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager.distanceFilter = 1000.0
        locationManager.requestWhenInUseAuthorization()
    }
    
    func userLoginInit(userId: String) {
        self.locationManager.startUpdatingLocation()
        self.setServiceReady()
    }
    
    var isLocationServiceEnabled:Bool{
        return CLLocationManager.locationServicesEnabled()
    }
    
    func refreshHere()
    {
        self.locationManager.startUpdatingLocation()
    }
    
    private var _here:CLLocation!
    private(set) var here:CLLocation!{
        get{
            #if DEBUG
                if isInSimulator() {
                    return CLLocation(latitude: 23.1, longitude: 113.3)
                }
            #endif
            return _here
        }
        set{
            _here = newValue
        }
    }
    
    var hereShortString:String?{
        if let here = self.here {
            return "{\"long\":\(here.coordinate.longitude),\"lati\":\(here.coordinate.latitude),\"alti\":\(here.altitude)}"
        }
        return nil
    }
    
    
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
