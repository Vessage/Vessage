//
//  SoundService.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/29.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreLocation

class LocationService:NotificationCenter,ServiceProtocol,CLLocationManagerDelegate
{
    @objc static var ServiceName:String{return "Location Service"}
    static let hereUpdated = "hereUpdated".asNotificationName()
    fileprivate var locationManager:CLLocationManager!
    @objc func appStartInit(_ appName:String) {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager.distanceFilter = 1000.0
        locationManager.requestWhenInUseAuthorization()
    }
    
    func userLoginInit(_ userId: String) {
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
    
    fileprivate var _here:CLLocation!
    fileprivate(set) var here:CLLocation!{
        get{
            #if DEBUG
                if _here == nil && isInSimulator() {
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last{
            here = newLocation
            self.post(name: LocationService.hereUpdated, object: self)
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
}

//MARK: ServiceContainer DI
extension ServiceContainer{
    static func getLocationService() -> LocationService {
        return ServiceContainer.getService(LocationService.self)
    }
}
