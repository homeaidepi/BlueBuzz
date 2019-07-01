/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension delegate of the WatchKit extension.
*/

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, CLLocationManagerDelegate, URLSessionDownloadDelegate {

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
    private var locationManager: CLLocationManager?
    private var sampleDownloadURL = URL(string: "http://devstreaming.apple.com/videos/wwdc/2015/802mpzd3nzovlygpbg/802/802_designing_for_apple_watch.pdf?dl=1")!
    
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
        
        locationManager = CLLocationManager()
        locationManager?.requestAlwaysAuthorization()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.delegate = self
        locationManager?.allowsBackgroundLocationUpdates = true
    }
    
    deinit {
        //cant deinit the location manager as we run in the background
        //        self.performSelector(onMainThread: #selector(deinitLocationManager), with: nil, waitUntilDone: true)
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        //scheduleRefresh()
        requestLocation()
    }
    
    func requestLocation()
    {
        locationManager?.requestLocation()
    }
    
    // Be sure to complete all the tasks - otherwise they will keep consuming the background executing
    // time until the time is out of budget and the app is killed.
    //
    // WKWatchConnectivityRefreshBackgroundTask should be completed after the pending data is received
    // so retain the tasks first. The retained tasks will be completed at the following cases:
    // 1. hasContentPending flips to false, meaning all the pending data is received. Pending data means
    //    the data received by the device prior to the WCSession getting activated.
    //    More data might arrive, but it isn't pending when the session activated.
    // 2. The end of the handle method.
    //    This happens when hasContentPending can flip to false before the tasks are retained.
    //
    // If the tasks are completed before the WCSessionDelegate methods are called, the data will be delivered
    // the app is running next time, so no data lost.
    //
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for _ in backgroundTasks {
            
            for task : WKRefreshBackgroundTask in backgroundTasks {
                print("received background task: ", task)
                // only handle these while running in the background
                if (WKExtension.shared().applicationState == .background) {
                    if task is WKApplicationRefreshBackgroundTask {
                        // this task is completed below, our app will then suspend while the download session runs
                        print("application task received, start URL session")
                        scheduleURLSession()
                    }
                }
                else if let urlTask = task as? WKURLSessionRefreshBackgroundTask {
                    let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: urlTask.sessionIdentifier)
                    let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue: nil)
                    
                    print("Rejoining session \(backgroundSession)")
                }
                // make sure to complete all tasks, even ones you don't handle
                task.setTaskCompleted()
            }
        }
    }
    
    func scheduleRefresh() {
        print("Scheduling refresh")
        // fire in 10 seconds
        let fireDate = Date(timeIntervalSinceNow: 10.0)
        // optional, any SecureCoding compliant data can be passed here
        let userInfo = ["reason" : "background update"] as NSDictionary
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error) in
            if (error == nil) {
                print("successfully scheduled background task, use the crown to send the app to the background and wait for handle:BackgroundTasks to fire.")
            }
        }
    }
    
    func scheduleURLSession() {
        let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: NSUUID().uuidString)
        backgroundConfigObject.sessionSendsLaunchEvents = true
        
        let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue: nil)
        
        let downloadTask = backgroundSession.downloadTask(with: sampleDownloadURL)
        downloadTask.resume()
    }
    
    func scheduleSnapshot() {
        // fire now, we're ready
        let fireDate = Date()
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: fireDate, userInfo: nil) { error in
            if (error == nil) {
                print("successfully scheduled snapshot.  All background work completed.")
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo url: URL) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss a"
        let someDateTime = formatter.string(from: Date())
        
        print("\(someDateTime) finished session url: \(url)")
        scheduleSnapshot()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // get current location from locationManager return result
        let currentLocation = locations[0]
        
        // send out the location data
        let commandStatus = CommandMessage(command: .sendMessageData,
                                           phrase: .transferring,
                                           location: currentLocation as CLLocation,
                                           timedColor: defaultColor,
                                           errorMessage: "")
        
        guard let data = try? JSONEncoder().encode(commandStatus) else { return }
        
        WCSession.default.sendMessageData(data, replyHandler: { replyHandler in
        }, errorHandler: { error in })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        let commandStatus = CommandMessage(command: .sendMessageData,
                                           phrase: .failed,
                                           location: emptyLocation,
                                           timedColor: defaultColor,
                                           errorMessage: error.localizedDescription)
        
        guard let data = try? JSONEncoder().encode(commandStatus) else { return }
        
        WCSession.default.sendMessageData(data, replyHandler: { replyHandler in
        }, errorHandler: { error in })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            locationManager?.requestLocation()
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
//
//extension ExtensionDelegate {
//    static var shared: ExtensionDelegate {
//        guard let delegate = WKExtension.shared().delegate as? ExtensionDelegate else {
//            fatalError("ExtensionDelegate")
//        }
//        return delegate
//    }
//}
