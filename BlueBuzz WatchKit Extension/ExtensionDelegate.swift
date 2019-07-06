/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension delegate of the WatchKit extension.
*/

import WatchKit
import WatchConnectivity
import UserNotifications

let CurrentModeKey = "CurrentMode"

class ExtensionDelegate: NSObject, WKExtensionDelegate, CLLocationManagerDelegate, URLSessionDownloadDelegate {

    private(set) var connectivityManager: ConnectivityManager?
    private(set) var notificationProcessor: NotificationProcessor!
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()

    // Hold the KVO observers as we want to keep oberving in the extension life time.
    //
    private var activationStateObservation: NSKeyValueObservation?
    private var hasContentPendingObservation: NSKeyValueObservation?

    // An array to keep the background tasks.
    //
    private var wcBackgroundTasks = [WKWatchConnectivityRefreshBackgroundTask]()
    
    private var command: Command?
    private var locationIsAvailable: Bool = false
    private var locationManager: CLLocationManager?
    private var lastLocation: CLLocation?
    private var currentLocation: CLLocation?
    private var blueBuzzWebActionApiKey = "97fefa7a-d1bd-49dd-92fe-704f0c9ba744:SbEAqeqWoz5kD8oiH8qSTcNzoOpzhKuxBIZFMz7BKVobLP7b5sqTi16Ek8SpKDeS"
    private var blueBuzzWebActionGetLocation = URL(string: "https://us-south.functions.cloud.ibm.com/api/v1/namespaces/matthew.vandergrift%40ibm.com_dev/actions/BlueBuzz/GetWatchOSLocation")!
    
    func applicationDidFinishLaunching() {
        UserDefaults.standard.register(defaults: [CurrentModeKey: Mode.undefined.rawValue])
        
        self.connectivityManager = try? ConnectivityManager()
        self.connectivityManager?.sessionBehavior = WatchSessionBehavior()
        
        self.notificationProcessor = NotificationProcessor(connectivityManager: self.connectivityManager)
        self.notificationProcessor.registerNotifications()
        UNUserNotificationCenter.current().delegate = self.notificationProcessor
    }
    
    func applicationDidBecomeActive() {
        let replyHandler = { (response: [String: Any]) -> Void in
            print ("Received Mode Response")
            guard let receivedMode = Mode(messageRepresentation: response) else { return }
            UserDefaults.standard.set(receivedMode.rawValue, forKey:CurrentModeKey)
            
            DispatchQueue.main.async {
                guard let interfaceController = WKExtension.shared().rootInterfaceController as? InterfaceController else { return }
                
                interfaceController.mode = receivedMode
            }
            
            self.locationManager = CLLocationManager()
            
            self.locationManager?.requestAlwaysAuthorization()
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager?.delegate = self
            self.locationManager?.allowsBackgroundLocationUpdates = true
            
            self.requestLocation()
            self.scheduleNotifications()
        }
        
        connectivityManager?.send(message: CommandMessage(command: .requestMode), queueIfNecessary: true, replyHandler: replyHandler) { (error: Error) in
            print ("Mode Request error \(error)")
        }
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        scheduleRefresh()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                // this task is completed below, our app will then suspend while the download session runs
                print("application task received, start URL session")
                scheduleURLSession()
                backgroundTask.setTaskCompleted()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompleted()
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: urlSessionTask.sessionIdentifier)
                let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue: nil)
                
                print("Rejoining session \(backgroundSession)")
                urlSessionTask.setTaskCompleted()
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
        
        // WKWatchConnectivityRefreshBackgroundTask should be completed – Otherwise they will keep consuming
        // the background executing time and eventually causes an app crash.
        // The timing to complete the tasks is when the current WCSession turns to not .activated or
        // hasContentPending flipped to false (see completeBackgroundTasks), so KVO is set up here to observe
        // the changes if the two properties.
        //
        activationStateObservation = WCSession.default.observe(\.activationState) { _, _ in
            DispatchQueue.main.async {
                self.completeBackgroundTasks()
            }
        }
        hasContentPendingObservation = WCSession.default.observe(\.hasContentPending) { _, _ in
            DispatchQueue.main.async {
                self.completeBackgroundTasks()
            }
        }
    }
    
    deinit {
        //cant deinit the location manager as we run in the background
        //        self.performSelector(onMainThread: #selector(deinitLocationManager), with: nil, waitUntilDone: true)
    }
    
    func requestLocation()
    {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager?.requestLocation()
        }
    }
    
    func getLastLocation() -> CLLocation?
    {
        return lastLocation
    }
    
    func getCurrentLocation() -> CLLocation?
    {
        return currentLocation
    }
    
    func locationAvailable() -> Bool{
        return locationIsAvailable
    }
    
    func scheduleNotifications() {
        print("Scheduling notifications")
        
        let content = UNMutableNotificationContent()
        content.title = "Checking Location"
        content.body = "Click here for more info"
        
        //let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        
        // Create the trigger as a repeating event.
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.second = 30
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let identifier = UUID().uuidString
        //let identifier = "Local Notification"
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if error != nil {
                // Handle any errors.
            } else {
                self.scheduleRefresh()
                self.requestLocation()
            }
            //notificationCenter.removeAllDeliveredNotifications()
        }
    }
    
    func scheduleRefresh() {
        print("Scheduling refresh")
        
        // fire in 3 seconds
        let fireDate = Date(timeIntervalSinceNow: 3.0)
        // optional, any SecureCoding compliant data can be passed here
        let userInfo = ["reason" : "background update"] as NSDictionary
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error) in
            if (error == nil) {
                print("successfully scheduled background task, use the crown to send the app to the background and wait for handle:BackgroundTasks to fire.")
            }
        }
    }
    
    func scheduleURLSession() {
        print("Scheduling URL Session")
        
        let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: NSUUID().uuidString)
        backgroundConfigObject.sessionSendsLaunchEvents = true
        
        let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue: nil)
        
        let downloadTask = backgroundSession.downloadTask(with: blueBuzzWebActionGetLocation)
        downloadTask.resume()
    }
    
    func scheduleSnapshot() {
        print("Scheduling Snapshot")
        
        // fire now, we're ready
        let fireDate = Date()
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: fireDate, userInfo: nil) { error in
            if (error == nil) {
                print("successfully scheduled snapshot.  All background work completed.")
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo url: URL) {
        print("url Session Start")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss a"
        let someDateTime = formatter.string(from: Date())
        
        print("\(someDateTime) End session url: \(url)")
        scheduleSnapshot()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // get current location from locationManager return result
        self.lastLocation = locations.last ?? CLLocation(latitude: emptyDegrees, longitude: emptyDegrees)
        let currentLocation = locations[0]
        self.currentLocation = currentLocation
        self.locationIsAvailable = true;
        
        // send out the location data
        let commandStatus = CommandStatus(command: .sendMessageData,
                                           phrase: .transferring,
                                           latitude: currentLocation.coordinate.latitude,
                                           longitude: currentLocation.coordinate.longitude,
                                           timedColor: defaultColor,
                                           errorMessage: "")
  
        guard let jsonData = try? JSONEncoder().encode(commandStatus) else { return }

//      let jsonString = String(data: jsonData, encoding: .utf8)
//      print(jsonString)
        
        WCSession.default.sendMessageData(jsonData, replyHandler: { replyHandler in
        }, errorHandler: { error in })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        
        self.locationIsAvailable = false;
        let commandStatus = CommandStatus(command: .sendMessageData,
                                           phrase: .failed,
                                           latitude: emptyDegrees,
                                           longitude: emptyDegrees,
                                           timedColor: defaultColor,
                                           errorMessage: error.localizedDescription)
        
        guard let data = try? JSONEncoder().encode(commandStatus) else { return }
        
        WCSession.default.sendMessageData(data, replyHandler: { replyHandler in
        }, errorHandler: { error in })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            requestLocation()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async {
            self.completeBackgroundTasks()
        }
    }

    // Compelete the background tasks, and schedule a snapshot refresh.
    //
    func completeBackgroundTasks() {
        guard !wcBackgroundTasks.isEmpty else { return }

        guard WCSession.default.activationState == .activated,
            WCSession.default.hasContentPending == false else { return }

        wcBackgroundTasks.forEach { $0.setTaskCompletedWithSnapshot(false) }

        // Use Logger to log the tasks for debug purpose. A real app may remove the log
        // to save the precious background time.
        //
        Logger.shared.append(line: "\(#function):\(wcBackgroundTasks) was completed!")

        // Schedule a snapshot refresh if the UI is updated by background tasks.
        //
        wcBackgroundTasks.removeAll()

    }
}
