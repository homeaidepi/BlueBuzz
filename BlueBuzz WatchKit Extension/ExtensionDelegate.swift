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
    
    private var blueBuzzAppGroup = "group.com.homeaidepi.bluebuzz1"
    private var locationManager: CLLocationManager?
    private var currentLocation: CLLocation = emptyLocation
    private var lastUpdatedLocationDateTime: Date?
    private var alerted: Bool = false;
    private var instanceId: String = ""
    private var secondsBeforeCheckingLocation: Int = 45
    private var secondsBeforeCheckingDistance: Int = 60
    private var distanceBeforeNotifying: Double = 100

    func applicationDidFinishLaunching() {
        
        initLocationManager()
        return
    }
    
    func initSettings() {
        self.instanceId = sessionDelegater.getInstanceIdentifier()
        self.secondsBeforeCheckingLocation = sessionDelegater.getSecondsBeforeCheckingLocation()
        self.secondsBeforeCheckingDistance = sessionDelegater.getSecondsBeforeCheckingDistance()
        self.distanceBeforeNotifying = sessionDelegater.getDistanceBeforeNotifying()
        
        // we are going to keep a guid that indicates a unique id or (instance) of this shared connection between watch and phone for the purposes of cloud communication
        //
        print(instanceId)
        print(secondsBeforeCheckingDistance)
        print(secondsBeforeCheckingLocation)
        print(distanceBeforeNotifying)
        
        if (instanceId == "")
        {
            sendInstanceIdMessage();
        }
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
        print("application will resign active")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if (sessionDelegater.checkLastUpdatedLocationDateTime(lastUpdatedLocationDateTime: lastUpdatedLocationDateTime) == false) {
            return
        }
        
        //Step 1 get current location from locationManager return result
        let location = locations[0]
        
        //set the current location in the extension delegate
        currentLocation = location
        let instanceId = sessionDelegater.getInstanceIdentifier()
        
        //send the companion phone app the location data if in range
        let commandStatus = CommandStatus(command: .sendMessageData,
                                          phrase: .sent,
                                          latitude: currentLocation.coordinate.latitude,
                                          longitude: currentLocation.coordinate.longitude,
                                          instanceId: instanceId,
                                          deviceId: "watchos",
                                          timedColor: defaultColor,
                                          errorMessage: emptyError)
        
        //send the cloud the current location information
        if (sessionDelegater.postLocationByInstanceId(commandStatus: commandStatus)) {
            lastUpdatedLocationDateTime = Date()
            
            if (WCSession.default.isReachable == false) {
                if (sessionDelegater.checkDistanceByInstanceId(commandStatus: commandStatus) == true) {
                    self.alerted = scheduleAlertNotifications()
                    if (self.alerted) {
                        WKInterfaceDevice.current().play(.failure)
                        WKInterfaceDevice.current().play(.notification)
                    }
                } else {
                    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                }
            } else {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let description = error.localizedDescription
        print(description)
        
        if (description.contains("error 0") == false) {
            setCurrentLocation(location: emptyLocation)
            scheduleWarningNotifications()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            self.locationManager?.requestLocation()
        }
    }
    
    public func postLocationByInstanceId(commandStatus: CommandStatus) -> Bool {
        return sessionDelegater.postLocationByInstanceId(commandStatus: commandStatus)
    }
    
    public func setCurrentLocation(location: CLLocation) {
        self.currentLocation = location
    }
    
    public func checkDistanceByInstanceId(commandStatus: CommandStatus) -> Bool {
        return sessionDelegater.checkDistanceByInstanceId(commandStatus: commandStatus)
    }
    
    public func getInstanceId() -> String {
        return sessionDelegater.getInstanceIdentifier()
    }

    public func getSecondsBeforeCheckingLocation() -> Int {
        return sessionDelegater.getSecondsBeforeCheckingLocation()
    }
    
    public func getSecondsBeforeCheckingDistance() -> Int {
        return sessionDelegater.getSecondsBeforeCheckingDistance()
    }
    
    func scheduleAlertNotifications() -> Bool {
        print("Scheduling alert notification")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization.
            if granted {
                
                // Schedule the request with the system.
                let notificationCenter = UNUserNotificationCenter.current()
                let content = UNMutableNotificationContent()
                
                let formatter = DateFormatter()
                formatter.dateFormat = "hh:mm:ss a"
                let now = formatter.string(from: Date())
                
                content.title = NSLocalizedString("Location Warning", comment: now)
                content.body =  NSLocalizedString("Distance to phone greater then \(self.sessionDelegater.getDistanceBeforeNotifying()) feet", comment: now)
                content.sound = UNNotificationSound.defaultCritical
                
                let trigger = UNTimeIntervalNotificationTrigger.init(
                    timeInterval: 30,
                    repeats: false)
                let identifier = UUID().uuidString
                let request = UNNotificationRequest.init(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                //notificationCenter.removeAllDeliveredNotifications()
                notificationCenter.add(request, withCompletionHandler: { (error) in
                    if error != nil {
                        // Handle any errors.
                        print (error!.localizedDescription)
                        self.alerted = false
                    }
                    else {
                        self.alerted = true
                    }
                })
            }
        }
        return self.alerted
    }
 
    func scheduleWarningNotifications() {
        print("Scheduling warning notification")

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
    
    private func sendInstanceIdMessage() {
        
        // we are going to keep a guid that indicates a unique id or (instance) of this shared connection between watch and phone for the purposes of cloud communication
        //
        var instanceId = sessionDelegater.getInstanceIdentifier()
        if (instanceId == "")
        {
            instanceId = UUID().uuidString
            sessionDelegater.saveInstanceIdentifier(instanceId: instanceId)
        }
        
        let commandStatus = CommandStatus(command: .sendMessageData,
                                          phrase: .sent,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          instanceId: instanceId,
                                          deviceId: "watchos",
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
        
        // Activate the session asynchronously as early as possible.
        // In the case of being background launched with a task, this may save some background runtime budget.
        //
        WCSession.default.delegate = sessionDelegater
        WCSession.default.activate()
        
        initSettings()
    }
}
