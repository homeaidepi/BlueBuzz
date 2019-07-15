/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension delegate of the WatchKit extension.
*/
import WatchKit
import WatchConnectivity
import UserNotifications
import CoreLocation

class ExtensionDelegate: WKURLSessionRefreshBackgroundTask, CLLocationManagerDelegate,  WKExtensionDelegate {

    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    private var locationManager: CLLocationManager?
    private var currentLocation: CLLocation = emptyLocation
    private var lastUpdatedLocationDateTime: Date?

    func applicationDidFinishLaunching() {
        initLocationManager()
        return
    }
    
    func initLocationManager()
    {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.startUpdatingLocation()
        //locationManager?.requestLocation()
    }
    
    func applicationDidBecomeActive() {
       return
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        print("application will resign active")
    }
    
    public func setCurrentLocation(location: CLLocation) -> String {
        self.currentLocation = location
        return sessionDelegater.getInstanceIdentifier()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // do work here
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompleted()
            default:
                // make sure to complete unhandled task types
                task.setTaskCompleted()
            }
        }
    }
    
    override init() {
        super.init()
        assert(WCSession.isSupported(), "BlueBuzz requires Apple Watch!")
        
        if WatchSettings.sharedContainerID.isEmpty {
            print("Specify shared container ID for WatchSettings.sharedContainerID to use watch settings!")
        }
        
        // Activate the session asynchronously as early as possible.
        // In the case of being background launched with a task, this may save some background runtime budget.
        //
        WCSession.default.delegate = sessionDelegater
        WCSession.default.activate()
        
        let instanceId = sessionDelegater.getInstanceIdentifier()
        // we are going to keep a guid that indicates a unique id or (instance) of this shared connection between watch and phone for the purposes of cloud communication
        //
        if (instanceId == "")
        {
            sendInstanceIdMessage();
        }
    }
    
    public func postLocationByInstanceId(commandStatus: CommandStatus, deviceId: String) -> Bool {
        return sessionDelegater.postLocationByInstanceId(commandStatus: commandStatus, deviceId: deviceId)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if (sessionDelegater.checkLastUpdatedLocationDateTime(lastUpdatedLocationDateTime: lastUpdatedLocationDateTime) == false) {
            return
        }
        
        //Step 1 get current location from locationManager return result
        let location = locations[0]
        
        //set the current location in the extension delegate
        let instanceId = setCurrentLocation(location: location)
        
        //send the companion phone app the location data if in range
        let commandStatus = CommandStatus(command: .sendMessageData,
                                          phrase: .sent,
                                          latitude: currentLocation.coordinate.latitude,
                                          longitude: currentLocation.coordinate.longitude,
                                          instanceId: instanceId,
                                          timedColor: defaultColor,
                                          errorMessage: emptyError)
        
        //send the cloud the current location information
        if (sessionDelegater.postLocationByInstanceId(commandStatus: commandStatus, deviceId: "watchos")) {
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            lastUpdatedLocationDateTime = Date()
        }
    }


    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let description = error.localizedDescription
        print(description)
        
        if (description.contains("Code: 0") == false) {
            _ = setCurrentLocation(location: emptyLocation)
            scheduleNotifications()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            self.locationManager?.requestLocation()
        }
    }
 
    func scheduleNotifications() {
        print("Scheduling notifications")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization.
            if granted {
                
                // Schedule the request with the system.
                let notificationCenter = UNUserNotificationCenter.current()
                let content = UNMutableNotificationContent()
                
                let formatter = DateFormatter()
                formatter.dateFormat = "hh:mm:ss a"
                let now = formatter.string(from: Date())
                
                if (self.currentLocation == emptyLocation)
                {
                    content.title = NSLocalizedString("Location Warning", comment: now)
                    content.body =  NSLocalizedString("Cant determine location", comment: now)
                    content.sound = UNNotificationSound.defaultCritical
                } else {
                    notificationCenter.removeAllDeliveredNotifications()
                    return
                }
                
                let trigger = UNTimeIntervalNotificationTrigger.init(
                    timeInterval: 3,
                    repeats: false)
                // Create the trigger as a repeating event.
//                var dateComponents = DateComponent()
//                dateComponents.calendar = Calendar.current
//                dateComponents.second = 30
//                let trigger = UNCalendarNotificationTrigger(
//                    dateMatching: dateComponents, repeats: true)
                let identifier = UUID().uuidString
                let request = UNNotificationRequest.init(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                notificationCenter.removeAllDeliveredNotifications()
                notificationCenter.add(request, withCompletionHandler: { (error) in
                    if error != nil {
                        // Handle any errors.
                        print (error!.localizedDescription)
                    }
                    else {
                        return;
                    }
                })
            }
        }
    }

    func scheduleRefresh() {
        print("Scheduling refresh")
        
        // fire in 10 seconds
        let fireDate = Date(timeIntervalSinceNow: 10.0)
        // optional, any SecureCoding compliant data can be passed here
        let userInfo = ["reason" : "background update"] as NSDictionary
        
        locationManager!.requestLocation()

        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error) in
            if (error == nil) {
                print("successfully scheduled background task")
            }
        }
    }
    
    private func sendInstanceIdMessage()
    {
        var instanceId = sessionDelegater.getInstanceIdentifier()
        // we are going to keep a guid that indicates a unique id or (instance) of this shared connection between watch and phone for the purposes of cloud communication
        //
        if (instanceId == "")
        {
            instanceId = UUID().uuidString
            sessionDelegater.saveInstanceIdentifier(identifier: instanceId)
        }
        
        let commandStatus = CommandStatus(command: .sendMessageData,
                                          phrase: .sent,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          instanceId: instanceId,
                                          timedColor: defaultColor,
                                          errorMessage: "")
        
        do {
            let data = try JSONEncoder().encode(commandStatus)
            
            //let jsonString = String(data: data, encoding: .utf8)!
            //print(jsonString)
            
            WCSession.default.sendMessageData(data, replyHandler: { replyHandler in
            }, errorHandler: { error in
                print("error")})
        } catch {
            print("Send Message Data")
        }
        
    }
    
    
}
