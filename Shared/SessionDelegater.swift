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

// Implement WCSessionDelegate methods to receive Watch Connectivity data and notify clients.
// WCsession status changes are also handled here.
//
class SessionDelegater: NSObject, WCSessionDelegate, URLSessionDelegate {
    
    var blueBuzzIbmSharingApiKey = "a5e5ee30-1346-4eaf-acdd-e1a7dccdec20"
    var blueBuzzWebServiceGetLocationByInstanceId = URL(string: "https://91ccdda5.us-south.apiconnect.appdomain.cloud/ea882ccc-8540-4ab2-b4e5-32ac20618606/getlocationbyinstanceid")!
    var blueBuzzWebServicePostLocation = URL(string: "https://91ccdda5.us-south.apiconnect.appdomain.cloud/ea882ccc-8540-4ab2-b4e5-32ac20618606/PostLocationByInstanceId")!
    var blueBuzzWebServiceCheckDistanceByInstanceId = URL(string: "https://91ccdda5.us-south.apiconnect.appdomain.cloud/ea882ccc-8540-4ab2-b4e5-32ac20618606/CheckDistanceByInstanceId")

    private var retval = false
    private var instanceId: String = ""
    private var secondsBeforeCheckingLocation: Int = 45
    private var secondsBeforeCheckingDistance: Int = 60
    private var distanceBeforeNotifying: Double = 100
    
    //Settings
    //
    public func registerSettings()
    {
        self.instanceId = getInstanceIdentifier()
        
        if (self.instanceId == emptyInstanceIdentifier) {
            initSettings()
        } else {
            self.secondsBeforeCheckingLocation = getSecondsBeforeCheckingLocation()
            self.secondsBeforeCheckingDistance = getSecondsBeforeCheckingDistance()
            self.distanceBeforeNotifying = getDistanceBeforeNotifying()
        }
    }
    
    func initSettings() {
        saveSecondsBeforeCheckingDistance(secondsBeforeCheckingDistance: 45)
        saveSecondsBeforeCheckingLocation(secondsBeforeCheckingLocation: 60)
        saveDistanceBeforeNotifying(distanceBeforeNotifying: 100)
    }
    
    func getSettings() -> [String: Any] {
        let settings = [
            instanceIdentifierKey: instanceId,
            secondsBeforeCheckingLocationKey: secondsBeforeCheckingLocation,
            secondsBeforeCheckingDistanceKey: secondsBeforeCheckingDistance,
            distanceBeforeNotifyingKey: distanceBeforeNotifying] as [String : Any]
        
        return settings;
    }
    
    func saveSettings(applicationContext: [String: Any]) {
        let instanceId = applicationContext[instanceIdentifierKey] as? String ?? ""
        let secondsBeforeCheckingLocation = applicationContext[secondsBeforeCheckingLocationKey] as? Int ?? 0
        let secondsBeforeCheckingDistance = applicationContext[secondsBeforeCheckingDistanceKey] as? Int ?? 0
        let distanceBeforeNotifying = applicationContext[distanceBeforeNotifyingKey] as? Double ?? 0
        
        if (instanceId != "") {
            saveInstanceIdentifier(instanceId: instanceId)
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
    
    //Seconds before checking location get set
    public func getSecondsBeforeCheckingLocation() -> Int {
        let defaults = UserDefaults.standard
        
        // Get the saved int from the standard UserDefaults with the key, "secondsSinceLastUpdatedLocation"
        let secondsBeforeCheckingLocation = defaults.integer(forKey: secondsBeforeCheckingLocationKey)
        
        return secondsBeforeCheckingLocation
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
        let instanceId = applicationContext[instanceIdentifierKey] as? String ?? emptyInstanceIdentifier
        
        
        let commandStatus = CommandStatus(command: .updateAppConnection,
                                          phrase: .received,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          instanceId: instanceId,
                                          deviceId: emptyDeviceIdentifier,
                                          timedColor: TimedColor(applicationContext),
                                          errorMessage: emptyError)
        
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
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
    //
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }
    
    public func postLocationByInstanceId(commandStatus: CommandStatus) -> Bool {
        let serviceUrl = blueBuzzWebServicePostLocation
        
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
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("a5e5ee30-1346-4eaf-acdd-e1a7dccdec20", forHTTPHeaderField: "X-IBM-Client-Id")
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
    
    public func checkDistanceByInstanceId(commandStatus: CommandStatus) -> Bool {
        let serviceUrl = blueBuzzWebServiceCheckDistanceByInstanceId!
        
        let instanceId = commandStatus.instanceId
        
        let parameterDictionary = [
            "instanceId" : "\(instanceId)",
        ]
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("a5e5ee30-1346-4eaf-acdd-e1a7dccdec20", forHTTPHeaderField: "X-IBM-Client-Id")
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
                        if (distance > self.distanceBeforeNotifying) {
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
            
            if (hoursSinceLastUpdatedLocation > 0) {
                return true
            }
            
            if (minutesSinceLastUpdatedLocation > 0) {
                return true
            }
            
            if (secondsSinceLastUpdatedLocation > secondsBeforeCheckingDistance) {
                return true
            }
        } else {
            return true
        }
        
        return false
    }
}
