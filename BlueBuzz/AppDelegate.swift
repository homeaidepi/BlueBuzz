/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app delegate class of the iOS app.
*/

import UIKit
import WatchConnectivity
import UserNotifications
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, URLSessionTaskDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var locationManager: CLLocationManager?
    private var currentLocation: CLLocation = emptyLocation
    private var lastUpdatedLocationDateTime: Date?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Trigger WCSession activation at the early phase of app launching.
        //
        #if DEBUG
        assert(WCSession.isSupported(), "BlueBuzz requires Apple Watch!")
        #endif
        WCSession.default.delegate = sessionDelegater
        WCSession.default.activate()
        
        registerSettings()
        registerForPushNotifications()
        registerForLocation()
        registerBackgroundTask()
        
        return true
    }
    
    func registerSettings() {
        sessionDelegater.registerSettings()
    }
    
    func saveInstanceIdentifier(instanceId: String) {
        sessionDelegater.saveInstanceIdentifier(instanceId: instanceId)
    }
    
    func registerForLocation()
    {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.startUpdatingLocation()
        //locationManager?.startMonitoringSignificantLocationChanges()
        //locationManager?.requestLocation()
    }
    
    func registerBackgroundTask() {
        // Fetch data once every 30 secs
        UIApplication.shared.setMinimumBackgroundFetchInterval(60)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Fetch no sooner than every (60) seconds which is thrillingly short actually.
        // Defaults to Infinite if not set.
        UIApplication.shared.setMinimumBackgroundFetchInterval( 60 )
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            // 1. Check if permission granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler:
        @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("application background fetch")
        var fetchResult: UIBackgroundFetchResult!
        
        locationManager!.startUpdatingLocation()
        fetchResult = UIBackgroundFetchResult.newData

        completionHandler( fetchResult )

        return
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 1. Convert device token to string
        //        let tokenParts = deviceToken.map { data -> String in
        //            return String(format: "%02.2hhx", data)
        //        }
        //let token = tokenParts.joined()
        // 2. Print device token to use for PNs payloads
        //print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // 1. Print out error if PNs registration not successful
        print("Failed to register for remote notifications with error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
        if (sessionDelegater.checkLastUpdatedLocationDateTime(lastUpdatedLocationDateTime: lastUpdatedLocationDateTime) == false) {
            return
        }
        
        //Step 1 get current location from locationManager return result
        let location = locations[0]
        currentLocation = location
        
        //set the current location in the extension delegate
        let instanceId = sessionDelegater.getInstanceIdentifier()
        
        //send the companion phone app the location data if in range
        let commandStatus = CommandStatus(command: .sendMessageData,
                                            phrase: .sent,
                                            latitude: currentLocation.coordinate.latitude,
                                            longitude: currentLocation.coordinate.longitude,
                                            instanceId: instanceId,
                                            deviceId: "ios",
                                            timedColor: defaultColor,
                                            errorMessage: emptyError)
        
        //send the cloud the current location information
        if (sessionDelegater.postLocationByInstanceId(commandStatus: commandStatus)) {
            lastUpdatedLocationDateTime = Date()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        //myDelegate.setCurrentLocation(location: emptyLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            self.locationManager?.startUpdatingLocation()
        }
    }
    
//    func setCurrentLocation(location: CLLocation) -> String {
//        self.currentLocation = location
//        return sessionDelegater.getInstanceIdentifier()
//    }
    
}
