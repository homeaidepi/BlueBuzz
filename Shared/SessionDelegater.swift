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

private var blueBuzzIbmSharingApiKey = "a5e5ee30-1346-4eaf-acdd-e1a7dccdec20"
private var blueBuzzWebServiceGetLocationByInstanceId = URL(string: "https://91ccdda5.us-south.apiconnect.appdomain.cloud/ea882ccc-8540-4ab2-b4e5-32ac20618606/getlocationbyinstanceid")!
private var blueBuzzWebServicePostLocation = URL(string: "https://91ccdda5.us-south.apiconnect.appdomain.cloud/ea882ccc-8540-4ab2-b4e5-32ac20618606/PostLocationByInstanceId")!
private var blueBuzzWebServiceCheckDistanceByInstanceId = URL(string: "https://91ccdda5.us-south.apiconnect.appdomain.cloud/ea882ccc-8540-4ab2-b4e5-32ac20618606/CheckDistanceByInstanceId")!


// Implement WCSessionDelegate methods to receive Watch Connectivity data and notify clients.
// WCsession status changes are also handled here.
//
class SessionDelegater: NSObject, WCSessionDelegate, URLSessionDelegate {
    
    private var retval = false
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
    func session(_ session: WCSession, didReceiveApplicationContext applicationConnection: [String: Any]) {
        let commandStatus = CommandStatus(command: .sendMessageData,
                                          phrase: .received,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          instanceId: emptyInstanceIdentifier,
                                          timedColor: TimedColor(applicationConnection),
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
                                          timedColor: TimedColor(message),
                                          errorMessage: emptyError)
        
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Called when a message is received and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        self.session(session, didReceiveMessage: message)
        replyHandler(message) // Echo back the time stamp.
    }
    
    // Called when a piece of message data is received and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        let commandStatus = try? JSONDecoder().decode(CommandStatus.self, from: messageData)
        
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
    
    public func getInstanceIdentifier() -> String
    {
        // String to be filled with the saved value from UserDefaults
        var instanceId:String = ""
        
        // Get the standard UserDefaults as "defaults"
        let defaults = UserDefaults.standard
        
        // Get the saved String from the standard UserDefaults with the key, "instanceId"
        instanceId = defaults.string(forKey: instanceIdentifierKey) ?? ""
        
        return instanceId
    }
    
    // we are going to keep a guid that indicates a unique id or (instance) of this shared connection for the purposes of cloud communication
    //
    public func saveInstanceIdentifier(identifier: String)
    {
        // Get the standard UserDefaults as "defaults"
        let defaults = UserDefaults.standard
        
        // Save the String to the standard UserDefaults under the key, instanceIdentifierKey
        defaults.set(identifier, forKey: instanceIdentifierKey)
    }
    
    public func postLocationByInstanceId(commandStatus: CommandStatus, deviceId: String) -> Bool {
        let serviceUrl = blueBuzzWebServicePostLocation
        
        let lat = commandStatus.latitude
        let long = commandStatus.longitude
        let instanceId = commandStatus.instanceId
        let deviceId = deviceId
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
        let serviceUrl = blueBuzzWebServiceCheckDistanceByInstanceId
        
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
                        if (distance > 10) {
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
            
            if (secondsSinceLastUpdatedLocation > 30) {
                return true
            }
        } else {
            return true
        }
        
        return false
    }
}
