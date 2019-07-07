/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension delegate of the WatchKit extension.
*/

import WatchKit
import WatchConnectivity
import UserNotifications

let CurrentModeKey = "CurrentMode"

class ExtensionDelegate: WKURLSessionRefreshBackgroundTask, WKExtensionDelegate {

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
    
    private var blueBuzzWebActionApiKey = "97fefa7a-d1bd-49dd-92fe-704f0c9ba744:SbEAqeqWoz5kD8oiH8qSTcNzoOpzhKuxBIZFMz7BKVobLP7b5sqTi16Ek8SpKDeS"
    private var blueBuzzWebActionGetLocation = URL(string: "https://us-south.functions.cloud.ibm.com/api/v1/namespaces/matthew.vandergrift%40ibm.com_dev/actions/BlueBuzz/GetWatchOSLocation")!
    
    func applicationDidFinishLaunching() {
        return
    }
    
    func applicationDidBecomeActive() {
       return
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        //scheduleRefresh()
        scheduleNotifications()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompleted()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompleted()
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
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
        
        // WKWatchConnectivityRefreshBackgroundTask should be completed – Otherwise they will keep consuming
        // the background executing time and eventually causes an app crash.
        // The timing to complete the tasks is when the current WCSession turns to not .activated or
        // hasContentPending flipped to false (see completeBackgroundTasks), so KVO is set up here to observe
        // the changes if the two properties.
        //
//        activationStateObservation = WCSession.default.observe(\.activationState) { _, _ in
//            DispatchQueue.main.async {
//                self.completeBackgroundTasks()
//            }
//        }
//        hasContentPendingObservation = WCSession.default.observe(\.hasContentPending) { _, _ in
//            DispatchQueue.main.async {
//                self.completeBackgroundTasks()
//            }
//        }

        // Activate the session asynchronously as early as possible.
        // In the case of being background launched with a task, this may save some background runtime budget.
        //
        WCSession.default.delegate = sessionDelegater
        WCSession.default.activate()
    }
 
    func scheduleNotifications() {
        print("Scheduling notifications")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            // Enable or disable features based on authorization.
            if granted {
                let content = UNMutableNotificationContent()
                
                // Create the trigger as a repeating event.
                //        var dateComponents = DateComponents()
                //        dateComponents.calendar = Calendar.current
                //        dateComponents.second = 30
                //        let trigger = UNCalendarNotificationTrigger(
                //            dateMatching: dateComponents, repeats: true)
                
                // Schedule the request with the system.
                let notificationCenter = UNUserNotificationCenter.current()
                content.title = NSLocalizedString("notificationTitle", comment: "")
                content.body =  NSLocalizedString("notificationText", comment: "")
                content.sound = UNNotificationSound.default
                //content.userInfo = userInfo
                let trigger = UNTimeIntervalNotificationTrigger.init(
                    timeInterval: 60,
                    repeats: true)
                
                let identifier = UUID().uuidString
                let request = UNNotificationRequest.init(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                notificationCenter.add(request, withCompletionHandler: nil)
                
                notificationCenter.removeAllDeliveredNotifications()
            }
            else {
                return
            }
        }
    }


//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        DispatchQueue.main.async {
//            self.completeBackgroundTasks()
//        }
//    }
    
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
        
        let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self as? URLSessionDelegate, delegateQueue: nil)
        
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
    
    // Compelete the background tasks, and schedule a snapshot refresh.
    //
//    func completeBackgroundTasks() {
//        guard !wcBackgroundTasks.isEmpty else { return }
//
//        guard WCSession.default.activationState == .activated,
//            WCSession.default.hasContentPending == false else { return }
//
//        wcBackgroundTasks.forEach { $0.setTaskCompletedWithSnapshot(false) }
//
//        // Use Logger to log the tasks for debug purpose. A real app may remove the log
//        // to save the precious background time.
//        //
//        //Logger.shared.append(line: "\(#function):\(wcBackgroundTasks) was completed!")
//
//        // Schedule a snapshot refresh if the UI is updated by background tasks.
//        //
//        wcBackgroundTasks.removeAll()
//
//    }
}
