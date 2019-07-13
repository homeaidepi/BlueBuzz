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

    private var blueBuzzIbmSharingApiKey = "a5e5ee30-1346-4eaf-acdd-e1a7dccdec20"
    private var blueBuzzWebServiceGetLocationByInstanceId = URL(string: "https://91ccdda5.us-south.apiconnect.appdomain.cloud/ea882ccc-8540-4ab2-b4e5-32ac20618606/getlocationbyinstanceid")!
    private var blueBuzzWebServicePostLocation = URL(string: "https://91ccdda5.us-south.apiconnect.appdomain.cloud/ea882ccc-8540-4ab2-b4e5-32ac20618606/PostLocationByInstanceId")!
    
    func applicationDidFinishLaunching() {
        return
    }
    
    func applicationDidBecomeActive() {
       return
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        scheduleRefresh()
        scheduleNotifications()
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
                locationManager?.requestLocation()
                scheduleRefresh()
                scheduleNotifications()
                
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //Step 1 get current location from locationManager return result
        let location = locations[0]
        
        //set the current location in the extension delegate
        let instanceId = setCurrentLocation(location: location)
        
        //send the companion phone app the location data if in range
        var commandStatus = CommandStatus(command: .sendMessageData,
                                          phrase: .sent,
                                          latitude: currentLocation.coordinate.latitude,
                                          longitude: currentLocation.coordinate.longitude,
                                          instanceId: instanceId,
                                          timedColor: defaultColor,
                                          errorMessage: emptyError)
        
        do {
            //send the cloud the current location information
            postLocationByInstanceId(commandStatus: commandStatus)
            
            let data = try JSONEncoder().encode(commandStatus)
            
            //let jsonString = String(data: data, encoding: .utf8)!
            //print(jsonString)
            
            //send the message out of the current command
            WCSession.default.sendMessageData(data, replyHandler: {
                replyHandler in
            },
                errorHandler: { error in
                commandStatus.errorMessage = error.localizedDescription
            })
            
        } catch {
            commandStatus.errorMessage = "Send Location Error"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        //myDelegate.setCurrentLocation(location: emptyLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            locationManager?.requestLocation()
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
                    //self.locationManager?.requestLocation()
                    return
                }
                
//                let trigger = UNTimeIntervalNotificationTrigger.init(
//                    timeInterval: 60,
//                    repeats: true)
                // Create the trigger as a repeating event.
                var dateComponents = DateComponents()
                dateComponents.calendar = Calendar.current
                dateComponents.second = 30
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents, repeats: true)
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
                        notificationCenter.removeAllDeliveredNotifications()
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

        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error) in
            if (error == nil) {
                print("successfully scheduled background task, use the crown to send the app to the background and wait for handle:BackgroundTasks to fire.")
            }
        }
    }
    
//    func scheduleURLSession() {
//        print("Scheduling URL Session")
//
//        let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: NSUUID().uuidString)
//        backgroundConfigObject.sessionSendsLaunchEvents = true
//
//        let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self as? URLSessionDelegate, delegateQueue: nil)
//
//        let downloadTask = backgroundSession.downloadTask(with: blueBuzzWebServicePostLocation)
//        downloadTask.resume()
//    }
//
//    func scheduleSnapshot() {
//        print("Scheduling Snapshot")
//
//        // fire now, we're ready
//        let fireDate = Date()
//        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: fireDate, userInfo: nil) { error in
//            if (error == nil) {
//                print("successfully scheduled snapshot.  All background work completed.")
//            }
//        }
//    }
    
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo url: URL) {
//        print("url Session Start")
//        let formatter = DateFormatter()
//        formatter.dateFormat = "hh:mm:ss a"
//        let someDateTime = formatter.string(from: Date())
//
//        print("\(someDateTime) End session url: \(url)")
//        scheduleSnapshot()
//    }
    
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
    
    public func postLocationByInstanceId(commandStatus: CommandStatus) {
        let serviceUrl = blueBuzzWebServicePostLocation
        
        let lat = commandStatus.latitude
        let long = commandStatus.longitude
        let instanceId = commandStatus.instanceId
        let deviceId = "watchos"
        
        let parameterDictionary = [
            "latitude" : "\(lat)",
            "longitude" : "\(long)",
            "instanceId" : "\(instanceId)",
            "deviceId" : "\(deviceId)",
        ]
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("a5e5ee30-1346-4eaf-acdd-e1a7dccdec20", forHTTPHeaderField: "X-IBM-Client-Id")
        guard let httpBody = try? JSONSerialization.data(
            withJSONObject: parameterDictionary,
            options: []) else {
            return
        }
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    print(json)
                } catch {
                    print(error)
                }
            }
            }.resume()
    }
}
