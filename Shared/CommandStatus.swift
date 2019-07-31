/*
See LICENSE folder for this sample’s licensing information.

Abstract:
CommandStatus struct wraps the command status. Used on both iOS and watchOS.
*/

import UIKit
import WatchConnectivity
import CoreLocation

// shared constants
//
var emptyDegrees = Double(0)
var emptyLocation = CLLocation(latitude: emptyDegrees, longitude: emptyDegrees)
var emptyError = String("")
var ibmBlueColor = UIColor(red: CGFloat(70)/255, green: CGFloat(107)/255, blue: CGFloat(176)/255, alpha: 1.0)
var defaultColor = TimedColor(ibmBlueColor)
var secondsBeforeCheckingLocationKey = "secondsBeforeCheckingLocation"
var secondsBeforeCheckingDistanceKey = "secondsBeforeCheckingDistance"
var distanceBeforeNotifyingKey = "distanceBeforeNotifying"
var instanceIdentifierKey = "instanceId"
var emptyInstanceIdentifier = String("")
var emptyDeviceIdentifier = String("")
var defaultSecondsBeforeCheckingLocation = 45
var defaultSecondsBeforeCheckingDistance = 60
var defaultDistanceBeforeNotifying = 100.00

// Avoid creating DateFormatter for time stamp as Logger may count into execution budget.
//
private var timeStampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm:ss a"
    return formatter
}()

public func Now() -> String {
    return timeStampFormatter.string(from: Date())
}
// Constants to identify the Watch Connectivity methods, also used as user-visible strings in UI.
//
enum Command: String, Codable {
    case updateAppConnection = "Sync Settings"
    //case sendMessage = "Send Message"
    case sendMessageData = "Update Paired Devices Loc: Lat, Long"
}

// Constants to identify the phrases of a Watch Connectivity communication.
//
enum Phrase: String, Codable {
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

class Color:Codable{
    
    private var _green:CGFloat = 0
    private var _blue:CGFloat = 0
    private var _red:CGFloat = 0
    private var alpha:CGFloat = 0
    
    init(color:UIColor) {
        color.getRed(&_red, green: &_green, blue: &_blue, alpha: &alpha)
    }
    
    var color:UIColor{
        get{
            return UIColor(red: _red, green: _green, blue: _blue, alpha: alpha)
        }
        set{
            newValue.getRed(&_red, green:&_green, blue: &_blue, alpha:&alpha)
        }
    }
    
    var cgColor:CGColor{
        get{
            return color.cgColor
        }
        set{
            UIColor(cgColor: newValue).getRed(&_red, green:&_green, blue: &_blue, alpha:&alpha)
        }
    }
}

extension UIColor {
    func data() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    class func color(withData data: Data) -> UIColor? {
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? UIColor
    }
}

// Wrap a timed color payload dictionary with a stronger type.
//
struct TimedColor: Codable {
    var timeStamp: String
    var colorData: Data
    var defaultValue: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case timeStamp
        case colorData
        case defaultValue
    }
    
    init(timeStamp: String,
         colorData: Data,
         defaultValue: Bool = true) {
        self.timeStamp = timeStamp
        self.colorData = colorData
        self.defaultValue = defaultValue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timeStamp, forKey: .timeStamp)
        try container.encode(colorData, forKey: .colorData)
        try container.encode(defaultValue, forKey: .defaultValue)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        timeStamp = try container.decode(String.self, forKey: .timeStamp)
        colorData = try container.decode(Data.self, forKey: .colorData)
        defaultValue = try container.decode(Bool.self, forKey: .defaultValue)
    }
    
    var color: Color {
        do {
            let color = try JSONDecoder().decode(Color.self, from: colorData)
            return color
        }
        catch {
            return Color(color: ibmBlueColor)
        }
    }
    
    var timedColor: [String: Any] {
        return [PayloadKey.timeStamp: timeStamp, PayloadKey.colorData: colorData]
    }
    
    init(_ timedColor: UIColor)
    {
        self.timeStamp = Now()
        self.colorData = timedColor.data()
        self.defaultValue = false
    }
    
    init(_ timedColor: [String: Any]) {
        let timeStamp = timedColor[PayloadKey.timeStamp] as? String ?? Now()
        let colorData = timedColor[PayloadKey.colorData] as? Data ?? ibmBlueColor.data()
        self.timeStamp = timeStamp
        self.colorData = colorData
        self.defaultValue = false
    }
    
    init(_ timedColor: Data) {
        
        var color = TimedColor(UIColor.red)
        do {
            color = try JSONDecoder().decode(TimedColor.self, from: timedColor)
        }
        catch {
        }

        self.timeStamp = color.timeStamp
        self.colorData = color.colorData
        self.defaultValue = color.defaultValue
    }
}

// Wrap the command status to bridge the commands status and UI.
//
struct CommandStatus: Codable {
    
    var command: Command
    var phrase: Phrase
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var instanceId: String
    var deviceId: String
    var timedColor: TimedColor
    var errorMessage: String
    
    enum CodingKeys: String, CodingKey {
        case command
        case phrase
        case latitude
        case longitude
        case instanceId
        case deviceId
        case timedColor
        case errorMessage
    }
    
    init(command: Command,
         phrase: Phrase,
         latitude: CLLocationDegrees,
         longitude: CLLocationDegrees,
         instanceId: String,
         deviceId: String,
         timedColor: TimedColor,
         errorMessage: String) {
        self.command = command
        self.phrase = phrase
        self.latitude = latitude
        self.longitude = longitude
        self.instanceId = instanceId
        self.deviceId = deviceId
        self.timedColor = timedColor
        self.errorMessage = errorMessage
    }
        
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(command, forKey: .command)
        try container.encode(phrase, forKey: .phrase)
        try container.encode(timedColor, forKey: .timedColor)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(instanceId, forKey: .instanceId)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(errorMessage, forKey: .errorMessage)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        command = try container.decode(Command.self, forKey: .command)
        phrase = try container.decode(Phrase.self, forKey: .phrase)
        latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        instanceId = try container.decode(String.self, forKey: .instanceId)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        timedColor = try container.decode(TimedColor.self, forKey: .timedColor)
        errorMessage = try container.decode(String.self, forKey: .errorMessage)
        
    }
}
