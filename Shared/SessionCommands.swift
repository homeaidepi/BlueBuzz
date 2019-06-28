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

        var commandStatus = CommandStatus(command: .updateAppConnection, phrase: .unauthorized)
        
        if (WCSession.default.activationState == .activated)
        {
            commandStatus = CommandStatus(command: .updateAppConnection, phrase: .authorized)
            commandStatus.timedColor = TimedColor(context)
        }
        else {
            let center = UNUserNotificationCenter.current()
            
            center.requestAuthorization(options: [.sound]) { (granted, error) in
                if granted {
                    commandStatus.phrase = .authorized
                } else {
                    commandStatus.phrase = .unauthorized
                }
            }
        }
        //let ibmBlueColor = UIColor(red: 70, green: 107, blue: 176);
        let newRed = CGFloat(70)/255
        let newGreen = CGFloat(107)/255
        let newBlue = CGFloat(176)/255
        
        let ibmBlueColor = UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
        
        let timedColor = TimedColor(ibmBlueColor)
        
        let message: [String:Any] = [
            PayloadKey.timeStamp : timedColor.timeStamp,
            PayloadKey.colorData : timedColor.colorData
        ]
        
        WCSession.default.sendMessage(message, replyHandler: { replyMessage in
            commandStatus.phrase = .replied
            commandStatus.timedColor = TimedColor(replyMessage)
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
            
        }, errorHandler: { error in
            commandStatus.phrase = .failed
            commandStatus.errorMessage = error.localizedDescription
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
        })
        
        commandStatus = CommandStatus(command: .updateAppConnection,
                                      phrase: .sent)
        commandStatus.timedColor = timedColor;
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Send a message if the session is activated and update UI with the command status.
    //
    func sendMessage(_ message: [String: Any]) {
        var commandStatus = CommandStatus(command: .sendMessage, phrase: .sent)
        commandStatus.timedColor = TimedColor(message)

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
        var commandStatus = CommandStatus(command: .sendMessageData, phrase: .sent)
        commandStatus.timedColor = TimedColor(messageData)
        commandStatus.location = location
        
        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }

        WCSession.default.sendMessageData(messageData, replyHandler: { replyData in
            commandStatus.phrase = .replied
            commandStatus.timedColor = TimedColor(replyData)
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)

        }, errorHandler: { error in
            commandStatus.phrase = .failed
            commandStatus.errorMessage = error.localizedDescription
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
        })
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
