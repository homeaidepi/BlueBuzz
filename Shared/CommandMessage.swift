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
var emptyLocation = CLLocation(latitude:0, longitude: 0)
var emptyError = String("")
var defaultColor = TimedColor(UIColor(red: CGFloat(70)/255, green: CGFloat(107)/255, blue: CGFloat(176)/255, alpha: 1.0)) //IBM Blue

// Constants to identify the Watch Connectivity methods, also used as user-visible strings in UI.
//
enum Command: String, Codable {
    case updateAppConnection = "Check Authorization"
    case sendMessage = "Send Message"
    case sendMessageData = "Send Location"
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
    var defaultColor: Color
    
    private enum CodingKeys: String, CodingKey {
        case timeStamp
        case colorData
        case defaultValue
        case defaultColor
    }
    
    init(timeStamp: String,
         colorData: Data,
         defaultValue: Bool = true,
         defaultColor: Color) {
        self.timeStamp = timeStamp
        self.colorData = colorData
        self.defaultValue = defaultValue
        self.defaultColor = defaultColor
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timeStamp, forKey: .timeStamp)
        try container.encode(colorData, forKey: .colorData)
        try container.encode(defaultValue, forKey: .defaultValue)
        try container.encode(defaultColor, forKey: .defaultColor)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        timeStamp = try container.decode(String.self, forKey: .timeStamp)
        colorData = try container.decode(Data.self, forKey: .colorData)
        defaultValue = try container.decode(Bool.self, forKey: .defaultValue)
        defaultColor = try container.decode(Color.self, forKey: .defaultColor)
        
    }
    
    var color: Color {
        
        if (defaultValue == true) { return Color(color: defaultColor.color) }
        
        var color = Color(color: UIColor.green)
        do {
            color = try JSONDecoder().decode(Color.self, from: colorData)
        }
        catch {
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
        self.colorData = timedColor.data()
        self.defaultValue = false
        self.defaultColor = Color(color: UIColor.yellow)
    }
    
    init(_ timedColor: [String: Any]) {
        guard let timeStamp = timedColor[PayloadKey.timeStamp] as? String,
            let colorData = timedColor[PayloadKey.colorData] as? Data else {
                fatalError("Timed color dictionary doesn't have right keys!")
        }
        self.timeStamp = timeStamp
        self.colorData = colorData
        self.defaultValue = false
        self.defaultColor = Color(color: UIColor.orange)
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
        self.defaultColor = color.defaultColor
    }
}

// Wrap the command status to bridge the commands status and UI.
//
struct CommandMessage: Codable {
    
    var command: Command
    var phrase: Phrase
    var location: CLLocation
    var timedColor: TimedColor
    var errorMessage: String
    
    enum CodingKeys: String, CodingKey {
        case command
        case phrase
        case location
        case timedColor
        case errorMessage
    }
    
    init(command: Command,
         phrase: Phrase,
         location: CLLocation,
         timedColor: TimedColor,
         errorMessage: String) {
        self.command = command
        self.phrase = phrase
        self.location = location
        self.timedColor = timedColor
        self.errorMessage = errorMessage
    }
        
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(command, forKey: .command)
        try container.encode(phrase, forKey: .phrase)
        try container.encode(timedColor, forKey: .timedColor)
        try container.encode(location, forKey: .location)
        try container.encode(errorMessage, forKey: .errorMessage)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        command = try container.decode(Command.self, forKey: .command)
        phrase = try container.decode(Phrase.self, forKey: .phrase)
        timedColor = try container.decode(TimedColor.self, forKey: .timedColor)
        errorMessage = try container.decode(String.self, forKey: .errorMessage)
        
        let locationcontainer = try decoder.container(keyedBy: CLLocation.CodingKeys.self)
        
        let latitude = try locationcontainer.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try locationcontainer.decode(CLLocationDegrees.self, forKey: .longitude)
        let altitude = try locationcontainer.decode(CLLocationDistance.self, forKey: .altitude)
        let horizontalAccuracy = try locationcontainer.decode(CLLocationAccuracy.self, forKey: .horizontalAccuracy)
        let verticalAccuracy = try locationcontainer.decode(CLLocationAccuracy.self, forKey: .verticalAccuracy)
        let speed = try locationcontainer.decode(CLLocationSpeed.self, forKey: .speed)
        let course = try locationcontainer.decode(CLLocationDirection.self, forKey: .course)
        let timestamp = try locationcontainer.decode(Date.self, forKey: .timestamp)
        
        location = CLLocation(coordinate: CLLocationCoordinate2DMake(latitude, longitude), altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: timestamp)
        
    }

    public struct LocationWrapper: Decodable {
        var location: CLLocation
        
        init(location: CLLocation) {
            self.location = location
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CLLocation.CodingKeys.self)
            
            let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
            let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
            let altitude = try container.decode(CLLocationDistance.self, forKey: .altitude)
            let horizontalAccuracy = try container.decode(CLLocationAccuracy.self, forKey: .horizontalAccuracy)
            let verticalAccuracy = try container.decode(CLLocationAccuracy.self, forKey: .verticalAccuracy)
            let speed = try container.decode(CLLocationSpeed.self, forKey: .speed)
            let course = try container.decode(CLLocationDirection.self, forKey: .course)
            let timestamp = try container.decode(Date.self, forKey: .timestamp)
            
            let location = CLLocation(coordinate: CLLocationCoordinate2DMake(latitude, longitude), altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: timestamp)
            
            self.init(location: location)
        }
    }
}

extension CLLocation: Encodable {
    public enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case altitude
        case horizontalAccuracy
        case verticalAccuracy
        case speed
        case course
        case timestamp
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
        try container.encode(verticalAccuracy, forKey: .verticalAccuracy)
        try container.encode(speed, forKey: .speed)
        try container.encode(course, forKey: .course)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
