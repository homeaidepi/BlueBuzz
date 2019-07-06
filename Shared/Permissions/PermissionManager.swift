//
//  PermissionManager.swift
//  PermissionManager
//
//  Created by Shivank Agarwal on 27/01/19.
//  Copyright © 2019 Shivank Agarwal. All rights reserved.
//

import UIKit
import CoreLocation
import Contacts
import UserNotifications

public protocol PermissionManagerDelegate: class {

    func requirePermission(_ aPermissionType: PermissionType)
}

public protocol LocationDelegate: PermissionManagerDelegate {
    
    func didUpdateLocations(_ locations:[CLLocation], _ manager: CLLocationManager)
    func didFailWithError(_ error:Error, _ manager: CLLocationManager)
    func didChangeAuthorizationStatus(_ status: CLAuthorizationStatus, _ manager: CLLocationManager)
}

public enum PermissionType {
    case permissionTypeNone
    case permissionTypeLocation
}

class PermissionManager: NSObject {

    static let sharedInstance = PermissionManager()

    var permissionType: PermissionType = .permissionTypeNone
    weak var locationDelegate: LocationDelegate?
    
    var locationManager = CLLocationManager()
    var lat: String = "0"
    var long: String = "0"

    func setPermissionType(permission: PermissionType) {

        permissionType = permission
        switch permissionType {
        case .permissionTypeLocation:
            initLocation()
        default:
            break
        }
    }
}
