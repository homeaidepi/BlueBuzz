/*
See LICENSE folder for this sample’s licensing information.

Abstract:
SessionCommands protocol defines an interface to wrap Watch Connectivity APIs and bridge the UI.
 Its extension implements Watch Connectivity commands.
 Used on both iOS and watchOS.
*/

import UIKit
import WatchConnectivity
import UserNotifications
import CoreLocation

enum SessionPages: String {
    case LogView = "History"
    case Settings = "Settings"
}
// Define an interface to wrap Watch Connectivity APIs and
// bridge the UI. Shared by the iOS app and watchOS app.
//
protocol SessionCommands {
    func updateApplicationContext(applicationContext: [String : Any])
    func sendMessageData(_ messageData: Data, location: CLLocation?, instanceId: String, deviceId: String)
}

// Implement the commands. Every command handles the communication and notifies clients
// when WCSession status changes or data flows. Shared by the iOS app and watchOS app.
//
extension SessionCommands {
 
    // This is where the settings sync!
    // Yes, that's it!
    // Just updateApplicationContext on the session with a string array of settings
    func updateApplicationContext(applicationContext: [String : Any]) throws {
        do {
            try WCSession.default.updateApplicationContext(applicationContext)
        } catch let error {
            throw error
        }
    }
    
    // Send  a piece of message data if the session is activated and update UI with the command status.
    //
    func sendMessageData(_ messageData: Data, location: CLLocation?, instanceId: String, deviceId: String) {
        
        var commandStatus =  CommandStatus(command: .sendMessageData,
                                         phrase: .sent,
                                         latitude: location?.coordinate.latitude ?? emptyDegrees,
                                         longitude: location?.coordinate.longitude ?? emptyDegrees,
                                         instanceId: instanceId,
                                         deviceId: deviceId,
                                         timedColor: TimedColor(messageData),
                                         errorMessage: emptyError)
        
//        guard WCSession.default.activationState == .activated else {
//            return handleSessionUnactivated(with: commandStatus)
//        }
        
        do {
            let data = try JSONEncoder().encode(commandStatus)

            WCSession.default.sendMessageData(data, replyHandler: { replyData in
                commandStatus.phrase = .replied
                commandStatus.timedColor = TimedColor(replyData)
                self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)

            }, errorHandler: { error in
                commandStatus.phrase = .failed
                commandStatus.errorMessage = error.localizedDescription
                self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
            })
        } catch { return }
        
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Post a notification on the main thread asynchronously.
    //
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }

    // Handle the session unactived error. WCSession commands require an activated session.
    //
    private func handleSessionUnactivated(with commandStatus: CommandStatus) {
        var mutableStatus = commandStatus
        mutableStatus.phrase = .failed
        mutableStatus.errorMessage =  "Session is not activated yet!"
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
}
