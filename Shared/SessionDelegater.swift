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
    static let applicationWillResignActive = Notification.Name("willResignActiveNotification")
}

// Implement WCSessionDelegate methods to receive Watch Connectivity data and notify clients.
// WCsession status changes are also handled here.
//
class SessionDelegater: NSObject, WCSessionDelegate {
    
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
        let commandStatus = CommandStatus(command: .updateAppConnection,
                                          phrase: .received,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          timedColor: TimedColor(applicationConnection),
                                          errorMessage: "")
        
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Called when a message is received and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let commandStatus = CommandStatus(command: .sendMessage,
                                          phrase: .received,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          timedColor: TimedColor(message),
                                          errorMessage: "")
        
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
        let commandStatus = CommandStatus(command: .sendMessageData,
                                          phrase: .received,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          timedColor: TimedColor(messageData),
                                          errorMessage: "")
        
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
}
