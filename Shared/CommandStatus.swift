/*
See LICENSE folder for this sample’s licensing information.

Abstract:
CommandStatus struct wraps the command status. Used on both iOS and watchOS.
*/

import UIKit
import WatchConnectivity

// Constants to identify the Watch Connectivity methods, also used as user-visible strings in UI.
//
enum Command: String {
    //case updateAppContext = "Check Device"
    case updateAppConnection = "Check Connection"
    case sendMessage = "Message Device"
    case sendMessageData = "Send Data"
    //case transferUserInfo = "Transfer User Info"
    //case transferFile = "Transfer File"
    //case transferCurrentComplicationUserInfo = "Transfer Complication User Info"
}

// Constants to identify the phrases of a Watch Connectivity communication.
//
enum Phrase: String {
    case connected = "Device Connected"
    case disconnected = "Device Disconnected"
    case updated = "Device Checked"
    case sent = "Sent"
    case received = "Received"
    case replied = "Replied"
    case transferring = "Transferring"
    case canceled = "Canceled"
    case finished = "Finished"
    case failed = "Failed"
    case authorized = "Authorized"
    case unauthorized = "Unauthorized"
}

// Wrap a timed color payload dictionary with a stronger type.
//
struct TimedColor {
    var timeStamp: String
    var colorData: Data
    var defaultValue: Bool = true
    var defaultColor: UIColor
    
    var color: UIColor {
        
        if (defaultValue == true)
        {
            return defaultColor
        }
        
        let optional = ((try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIColor.self], from: colorData)) as Any??)
        guard let color = optional as? UIColor else {
            let newRed = CGFloat(70)/255
            let newGreen = CGFloat(107)/255
            let newBlue = CGFloat(176)/255
            return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
        }
        return color
    }
    
    var timedColor: [String: Any] {
        return [PayloadKey.timeStamp: timeStamp, PayloadKey.colorData: colorData]
    }
    
    init(_ timedColor: UIColor)
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss a"
        let someDateTime = formatter.string(from: Date())
        
        self.timeStamp = someDateTime
        self.colorData = Data()
        self.defaultValue = true
        self.defaultColor = timedColor
    }
    
    init(_ timedColor: [String: Any]) {
        guard let timeStamp = timedColor[PayloadKey.timeStamp] as? String,
            let colorData = timedColor[PayloadKey.colorData] as? Data else {
                fatalError("Timed color dictionary doesn't have right keys!")
        }
        self.timeStamp = timeStamp
        self.colorData = colorData
        self.defaultValue = false
        self.defaultColor = UIColor()
    }
    
    init(_ timedColor: Data) {
        let data = ((try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(timedColor)) as Any??)
        guard let dictionary = data as? [String: Any] else {
            fatalError("Failed to unarchive a timedColor dictionary!")
        }
        self.init(dictionary)
    }
}

// Wrap the command status to bridge the commands status and UI.
//
struct CommandStatus {
    var command: Command
    var phrase: Phrase
    var timedColor: TimedColor?
    var fileTransfer: WCSessionFileTransfer?
    var file: WCSessionFile?
    var userInfoTranser: WCSessionUserInfoTransfer?
    var errorMessage: String?
    
    init(command: Command, phrase: Phrase) {
        self.command = command
        self.phrase = phrase
    }
}
