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

// Define an interface to wrap Watch Connectivity APIs and
// bridge the UI. Shared by the iOS app and watchOS app.
//
protocol SessionCommands {
    func updateAppConnection(_ context: [String: Any])
    func sendMessage(_ message: [String: Any])
    func sendMessageData(_ messageData: Data, location: CLLocation?)
}

// Implement the commands. Every command handles the communication and notifies clients
// when WCSession status changes or data flows. Shared by the iOS app and watchOS app.
//
extension SessionCommands {
    // Update app connection if the session is activated and update UI with the command status.
    //
    func updateAppConnection(_ context: [String: Any]) {

        var command = CommandMessage(command: .updateAppConnection,
                                          phrase: .unauthorized,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          timedColor: defaultColor,
                                          errorMessage: emptyError)
        
        if (WCSession.default.activationState == .activated)
        {
            command.phrase = .authorized
        }
        else {
            let center = UNUserNotificationCenter.current()
            
            center.requestAuthorization(options: [.sound]) { (granted, error) in
                if granted {
                    command.phrase = .authorized
                } else {
                    command.phrase = .unauthorized
                    command.errorMessage = "You have not accepted location services."
                }
            }
        }

        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: command)
    }
    
    // Send a message if the session is activated and update UI with the command status.
    //
    func sendMessage(_ message: [String: Any]) {
        var commandStatus = CommandMessage(command: .sendMessage,
                                          phrase: .sent,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          timedColor: TimedColor(message),
                                          errorMessage: emptyError)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        
        WCSession.default.sendMessage(message, replyHandler: { replyMessage in
            commandStatus.phrase = .replied
            commandStatus.timedColor = TimedColor(replyMessage)
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)

        }, errorHandler: { error in
            commandStatus.phrase = .failed
            commandStatus.errorMessage = error.localizedDescription
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
        })
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Send  a piece of message data if the session is activated and update UI with the command status.
    //
    func sendMessageData(_ messageData: Data, location: CLLocation?) {
        
        var commandMessage =  CommandMessage(command: .sendMessageData,
                                         phrase: .sent,
                                         latitude: location?.coordinate.latitude ?? emptyDegrees,
                                         longitude: location?.coordinate.longitude ?? emptyDegrees,
                                         timedColor: TimedColor(messageData),
                                         errorMessage: emptyError)
        
        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandMessage)
        }
        
        do {
            let data = try JSONEncoder().encode(commandMessage)

            WCSession.default.sendMessageData(data, replyHandler: { replyData in
                commandMessage.phrase = .replied
                commandMessage.timedColor = TimedColor(replyData)
                self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandMessage)

            }, errorHandler: { error in
                commandMessage.phrase = .failed
                commandMessage.errorMessage = error.localizedDescription
                self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandMessage)
            })
        } catch { return }
        
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandMessage)
    }
    
    // Post a notification on the main thread asynchronously.
    //
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandMessage) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }

    // Handle the session unactived error. WCSession commands require an activated session.
    //
    private func handleSessionUnactivated(with commandStatus: CommandMessage) {
        var mutableStatus = commandStatus
        mutableStatus.phrase = .failed
        mutableStatus.errorMessage =  "Session is not activated yet!"
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
}
