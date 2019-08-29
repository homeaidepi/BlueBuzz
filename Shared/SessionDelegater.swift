/*
See LICENSE folder for this sample’s licensing information.

Abstract:
SessionDelegater implemments the WCSessionDelegate methods. Used on both iOS and watchOS.
*/

import Foundation
import WatchConnectivity
import CoreLocation

#if os(watchOS)
import ClockKit
#endif

// Custom notifications.
// Posted when Watch Connectivity activation or reachibility status is changed,
// or when data is received or sent. Clients observe these notifications to update the UI.
//
extension Notification.Name {
    static let dataDidFlow = Notification.Name("DataDidFlow")
    static let activationDidComplete = Notification.Name("ActivationDidComplete")
    static let reachabilityDidChange = Notification.Name("ReachabilityDidChange")
}

var messageKey = "message"
var emptyMessage = ""

// Implement WCSessionDelegate methods to receive Watch Connectivity data and notify clients.
// WCsession status changes are also handled here.
//
class SessionDelegater: NSObject, WCSessionDelegate, URLSessionDelegate {
    var message = emptyMessage;
    var blueBuzzIbmSharingApiKey = "11d31806-6344-4d16-9b54-dc27cdecfc1d"
    var blueBuzzWebServiceBaseAddress = "https://0ef58499.us-east.apiconnect.appdomain.cloud/dfb98ba5-6be0-4704-b70c-885b7817ccb5"
    var blueBuzzWebServiceGetLocationByInstanceId = "Getlocationbyinstanceid"
    var blueBuzzWebServicePostLocation = "PostLocationByInstanceId"
    var blueBuzzWebServiceCheckDistanceByInstanceId = "CheckDistanceByInstanceId"
    var blueBuzzWebServiceGetChangeLogByVersion = "GetChangeLogByVersion"
    var blueBuzzWebServicePostComment = "PostComment"
    var acceptType = "Application/json"
    var headerType = "Content-Type"
    var apiFieldName = "X-IBM-Client-Id"

    private var retval = false
    
    func getURL(string: String) -> URL {
        let url = "\(blueBuzzWebServiceBaseAddress)/\(string)"
        return URL(string: url)!
    }
   
    //Settings
    //
    public func registerSettings()
    {
        let instanceId = getInstanceIdentifier()
        
        if (instanceId == emptyInstanceIdentifier) {
            initSettings()
        }
    }
    
    func initSettings() {
        sendInstanceIdMessage(deviceId: "ios")
        saveSecondsBeforeCheckingDistance(secondsBeforeCheckingDistance: defaultSecondsBeforeCheckingLocation)
        saveSecondsBeforeCheckingLocation(secondsBeforeCheckingLocation: defaultSecondsBeforeCheckingDistance)
        saveDistanceBeforeNotifying(distanceBeforeNotifying: defaultDistanceBeforeNotifying)
        saveShowBackground(showBackground: defaultShowBackground)
    }
    
    func sendInstanceIdMessage(deviceId: String) {
        
        // we are going to keep a guid that indicates a unique id or (instance) of this shared connection between watch and phone for the purposes of cloud communication
        //
        var instanceId = getInstanceIdentifier()
        if (instanceId == emptyInstanceIdentifier)
        {
            instanceId = UUID().uuidString
            saveInstanceIdentifier(instanceId: instanceId)
        }
        
        let commandStatus = CommandStatus(command: .sendMessageData,
                                          phrase: .sent,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          instanceId: instanceId,
                                          deviceId: deviceId,
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
    
    func getSettings() -> [String: Any] {
        let settings = [
            instanceIdentifierKey: getInstanceIdentifier(),
            secondsBeforeCheckingLocationKey: getSecondsBeforeCheckingLocation(),
            secondsBeforeCheckingDistanceKey: getSecondsBeforeCheckingDistance(),
            distanceBeforeNotifyingKey: getDistanceBeforeNotifying(),
            showBackgroundKey: getShowBackground()] as [String : Any]
        return settings;
    }
    
    func saveSettings(applicationContext: [String: Any]) {
        let instanceId = applicationContext[instanceIdentifierKey] as? String ?? emptyInstanceIdentifier
        let secondsBeforeCheckingLocation = applicationContext[secondsBeforeCheckingLocationKey] as? Int ?? 0
        let secondsBeforeCheckingDistance = applicationContext[secondsBeforeCheckingDistanceKey] as? Int ?? 0
        let distanceBeforeNotifying = applicationContext[distanceBeforeNotifyingKey] as? Double ?? 0
        let showBackground = applicationContext[showBackgroundKey] as? Bool ?? true
        
        if (instanceId != emptyInstanceIdentifier) {
            saveInstanceIdentifier(instanceId: instanceId)
        } else {
            sendInstanceIdMessage(deviceId: "ios")
        }
        
        if (secondsBeforeCheckingLocation != 0) {
            saveSecondsBeforeCheckingLocation(secondsBeforeCheckingLocation: secondsBeforeCheckingLocation)
        }
        if (secondsBeforeCheckingDistance != 0) {
            saveSecondsBeforeCheckingDistance(secondsBeforeCheckingDistance: secondsBeforeCheckingDistance)
        }
        if (distanceBeforeNotifying != 0) {
            saveDistanceBeforeNotifying(distanceBeforeNotifying: distanceBeforeNotifying )
        }
        
        saveShowBackground(showBackground: showBackground)
    }
    
    //instance id get set
    public func getInstanceIdentifier() -> String {
        let defaults = UserDefaults.standard
        
        // Get the saved String from the standard UserDefaults with the key, "instanceId"
        let instanceId = defaults.string(forKey: instanceIdentifierKey) ?? ""
        
        return instanceId
    }
    
    public func saveInstanceIdentifier(instanceId: String) {
        let defaults = UserDefaults.standard
        
        defaults.set(instanceId, forKey: instanceIdentifierKey)
    }
    
    public func getWelcomeMessage(completion:@escaping (Bool) -> () )
    {
        var message: String = ""
        if (Variables.welcomeMessage.count < 30) {
            getChangeLogByVersion(onSuccess: { (JSON) in
                
            message = JSON[messageKey] as? String ?? emptyMessage
            
            Variables.welcomeMessage = message
                
            completion(true)
                
            }) { (error, params) in
            if let err = error {
                message = "\nError: " + err.localizedDescription
            }
            message += "\nParameters passed are: " + String(describing:params)
            
            Variables.welcomeMessage = message
        
            completion(false)
            }
        }
    }
    
    //Seconds before checking location get set
    public func getSecondsBeforeCheckingLocation() -> Int {
        let defaults = UserDefaults.standard
        
        // Get the saved int from the standard UserDefaults with the key, "secondsSinceLastUpdatedLocation"
        let secondsBeforeCheckingLocation = defaults.integer(forKey: secondsBeforeCheckingLocationKey)
        
        return secondsBeforeCheckingLocation
    }
    
    public func saveShowBackground
        (showBackground: Bool) {
        let defaults = UserDefaults.standard
        
        defaults.set(showBackground, forKey: showBackgroundKey)
    }
    
    public func getShowBackground() -> Bool {
        let defaults = UserDefaults.standard
        
        let showBackground = defaults.bool(forKey: showBackgroundKey)
        
        return showBackground
    }
    
    public func saveSecondsBeforeCheckingLocation(secondsBeforeCheckingLocation: Int) {
        let defaults = UserDefaults.standard
        
        defaults.set(secondsBeforeCheckingLocation, forKey: secondsBeforeCheckingLocationKey)
    }
    
    //Seconds before checking distance get set
    public func getSecondsBeforeCheckingDistance() -> Int {
        let defaults = UserDefaults.standard
        
        let secondsBeforeCheckingDistance = defaults.integer(forKey: secondsBeforeCheckingDistanceKey)
        
        return secondsBeforeCheckingDistance
    }
    
    public func saveSecondsBeforeCheckingDistance(secondsBeforeCheckingDistance: Int) {
        let defaults = UserDefaults.standard
        
        defaults.set(secondsBeforeCheckingDistance, forKey: secondsBeforeCheckingDistanceKey)
    }
    
    //Distance Before Notifying get set
    public func getDistanceBeforeNotifying() -> Double {
        let defaults = UserDefaults.standard
        
        let distanceBeforeNotifying = defaults.double(forKey: distanceBeforeNotifyingKey)
        
        return distanceBeforeNotifying
    }
    
    public func saveDistanceBeforeNotifying(distanceBeforeNotifying: Double) {
        let defaults = UserDefaults.standard
        
        defaults.set(distanceBeforeNotifying, forKey: distanceBeforeNotifyingKey)
    }
    
    // Called when WCSession activation state is changed.
    //
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        postNotificationOnMainQueueAsync(name: .activationDidComplete)
    }
    
    // Called when WCSession reachability is changed.
    //
    func sessionReachabilityDidChange(_ session: WCSession) {
        postNotificationOnMainQueueAsync(name: .reachabilityDidChange)
    }
    
    // Called when an app context is received.
    //
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        
        DispatchQueue.main.async { [weak self] in do {
            
            let instanceId = applicationContext[instanceIdentifierKey] as? String ?? emptyInstanceIdentifier
            let secondsBeforeCheckingLocation = applicationContext[secondsBeforeCheckingLocationKey] as? Int ?? 0
            let secondsBeforeCheckingDistance = applicationContext[secondsBeforeCheckingDistanceKey] as? Int ?? 0
            let distanceBeforeNotifying = applicationContext[distanceBeforeNotifyingKey] as? Double ?? 0
            
            if (instanceId != emptyInstanceIdentifier) {
                self?.saveInstanceIdentifier(instanceId: instanceId)
            }
            
            if (secondsBeforeCheckingLocation != 0) {
                self?.saveSecondsBeforeCheckingLocation(secondsBeforeCheckingLocation: secondsBeforeCheckingLocation)
            }
            
            if (secondsBeforeCheckingDistance != 0) {
                self?.saveSecondsBeforeCheckingDistance(secondsBeforeCheckingDistance: secondsBeforeCheckingDistance)
            }
            
            if (distanceBeforeNotifying != 0) {
                self?.saveDistanceBeforeNotifying(distanceBeforeNotifying: distanceBeforeNotifying)
            }
            
            if (instanceId != emptyInstanceIdentifier) {
                let commandStatus = CommandStatus(command: .updateAppConnection,
                                                  phrase: .received,
                                                  latitude: emptyDegrees,
                                                  longitude: emptyDegrees,
                                                  instanceId: instanceId,
                                                  deviceId: emptyDeviceIdentifier,
                                                  timedColor: TimedColor(applicationContext),
                                                  errorMessage: emptyError)
                
                self?.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
            } else {
                print("Error Getting App Context")
            }
            }
        }
    }
    
    // Called when a message is received and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let commandStatus = CommandStatus(command: .sendMessageData,
                                          phrase: .received,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          instanceId: emptyInstanceIdentifier,
                                          deviceId: emptyDeviceIdentifier,
                                          timedColor: TimedColor(message),
                                          errorMessage: emptyError)
        
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Called when a message is received and the peer needs a response.
    //
    //    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    //        self.session(session, didReceiveMessage: message)
    //        replyHandler(message) // Echo back the time stamp.
    //    }
    
    // Called when a piece of message data is received and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        var commandStatus = try? JSONDecoder().decode(CommandStatus.self, from: messageData)
        
        commandStatus?.phrase = .received
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Called when a piece of message data is received and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        self.session(session, didReceiveMessageData: messageData)
        replyHandler(messageData) // Echo back the time stamp.
    }
    
    // WCSessionDelegate methods for iOS only.
    //
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    #endif
    
    // Post a notification on the main thread asynchronously.
    //  Same as SessionCommands.swift
    public func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }
    
    public func postLocationByInstanceId(commandStatus: CommandStatus) -> Bool {
        let serviceUrl = getURL(string: blueBuzzWebServicePostLocation)
        
        let lat = commandStatus.latitude
        let long = commandStatus.longitude
        let instanceId = commandStatus.instanceId
        let deviceId = commandStatus.deviceId
        var retval = true
        
        let parameterDictionary = [
            "latitude" : "\(lat)",
            "longitude" : "\(long)",
            "instanceId" : "\(instanceId)",
            "deviceId" : "\(deviceId)",
        ]
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue(acceptType, forHTTPHeaderField: headerType)
        request.setValue(blueBuzzIbmSharingApiKey, forHTTPHeaderField: apiFieldName)
        guard let httpBody = try? JSONSerialization.data(
            withJSONObject: parameterDictionary,
            options: []) else {
                return false
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
                    retval = true
                } catch {
                    print(error)
                    retval = false
                }
            }
            }.resume()
        
        return retval
    }
    
    func callApiWithParams(_ params: [AnyHashable: Any], serviceUrl: URL,
                           onSuccess success: @escaping (_ JSON: [String: Any]) -> Void,
                                  onFailure failure: @escaping (_ error: Error?, _ params: [AnyHashable: Any]) -> Void) {
        
        print("\n" + String(describing: params))
        
        var request = URLRequest(url: serviceUrl)
        
        request.httpMethod = "POST"
        request.setValue(acceptType, forHTTPHeaderField: headerType)
        request.setValue(blueBuzzIbmSharingApiKey, forHTTPHeaderField: apiFieldName)
        guard let httpBody = try? JSONSerialization.data(
            withJSONObject: params,
            options: []) else {
                return;
        }
        request.httpBody = httpBody
        
        let session = URLSession.shared
        
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
                    //print(json);
                    if (json != nil) {
                        success(json!)
                    } else {
                        failure(NSError(domain:"Welcome message was nil", code:1, userInfo:nil), params)
                    }
                } catch {
                    print(error)
                    failure(error, params)
                }
            }
            }.resume()
    }
    
    public func getChangeLogByVersion(onSuccess success: @escaping (_ JSON: [String: Any]) -> Void,
                                      onFailure failure: @escaping (_ error: Error?, _ params: [AnyHashable: Any]) -> Void) {
        // dont fetch if already fetched
        if (self.message == emptyMessage) {
            let serviceUrl = getURL(string: blueBuzzWebServiceGetChangeLogByVersion)
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            
            let parameterDictionary = [
                "version" : "\(appVersion)",]
            
            callApiWithParams(parameterDictionary,
                              serviceUrl: serviceUrl,
                              onSuccess: success,
                              onFailure: failure)
        }
    }
    
    public func postComment(parameterDictionary: [String:String], onSuccess success: @escaping (_ JSON: [String: Any]) -> Void, onFailure failure: @escaping (_ error: Error?, _ params: [AnyHashable: Any]) -> Void) {

            let serviceUrl = getURL(string: blueBuzzWebServicePostComment)
            
            callApiWithParams(parameterDictionary,
                                  serviceUrl: serviceUrl,
                                  onSuccess: success,
                                  onFailure: failure)
    }
    
    
    public func checkDistanceByInstanceId(commandStatus: CommandStatus) -> Bool {
        let serviceUrl = getURL(string: blueBuzzWebServiceCheckDistanceByInstanceId)
        
        let instanceId = commandStatus.instanceId
        
        let parameterDictionary = [
            "instanceId" : "\(instanceId)",
        ]
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(blueBuzzIbmSharingApiKey, forHTTPHeaderField: "X-IBM-Client-Id")
        guard let httpBody = try? JSONSerialization.data(
            withJSONObject: parameterDictionary,
            options: []) else {
                return false
        }
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
                    //print(json ?? {})
                    
                    if let distance = json?["distance"] as? Double {
                        print("distance: \(distance)")
                        if (distance > self.getDistanceBeforeNotifying()) {
                            self.retval = true
                        }
                    }
                } catch {
                    print(error)
                    self.retval = false
                }
            }
            }.resume()
        
        return self.retval
    }
    
    func checkLastUpdatedLocationDateTime(lastUpdatedLocationDateTime: Date?) -> Bool {
        
        if (lastUpdatedLocationDateTime != nil) {
            let calendar = Calendar.current
            let componentSet: Set = [Calendar.Component.hour, .minute, .second]
            let components = calendar.dateComponents(componentSet, from: lastUpdatedLocationDateTime!, to: Date())
            let minutesSinceLastUpdatedLocation = components.minute!
            let hoursSinceLastUpdatedLocation = components.hour!
            let secondsSinceLastUpdatedLocation = components.second!
            
            let (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(getSecondsBeforeCheckingLocation()))
            
            //ran location  before a setting came back
            if ( h == 0 && m == 0 && s == 0) {
                return false
            }
            
            if (hoursSinceLastUpdatedLocation > h) {
                return true
            }
            
//            if (minutesSinceLastUpdatedLocation > m) {
//                return true
//            }
            
            if (secondsSinceLastUpdatedLocation > s && minutesSinceLastUpdatedLocation > m) {
                return true
            }
        } else {
            return true
        }
        
        return false
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
}
