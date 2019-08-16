/*
See LICENSE folder for this sample’s licensing information.

Abstract:
TestDataProvider protocol defines the interface for providing payload for Watch Connectivity APIs.
 Its extension provides default payload for the coomands.
*/

import UIKit
import CoreLocation

// Constants to access the payload dictionary.
// isCurrentComplicationInfo is to tell if the userInfo is from transferCurrentComplicationUserInfo
//
struct PayloadKey {
    static let timeStamp = "timeStamp"
    static let colorData = "colorData"
    static let isCurrentComplicationInfo = "isCurrentComplicationInfo"
}

// Define the interfaces for providing payload for Watch Connectivity APIs.
// MainViewController and MainInterfaceController adopt this protocol.
//
protocol TestDataProvider {
    var appConnection: [String: Any] { get }
    var message: [String: Any] { get }
    var messageData: Data { get }
}

// Generate default payload for commands, which contains a random color and a time stamp.
//
extension TestDataProvider {
    
    // Generate a dictionary containing a time stamp and a random color data.
    //
    private func timedColor() -> [String: Any] {
        let red = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let green = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let blue = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        
        let randomColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
        
        let data = try? NSKeyedArchiver.archivedData(withRootObject: randomColor, requiringSecureCoding: false)
        guard let colorData = data else { fatalError("Failed to archive a UIColor!") }
        
        return [PayloadKey.timeStamp: Now(), PayloadKey.colorData: colorData]
    }
    
    // Generate an app connection, used as the payload for updateAppConnection.
    //
    var appConnection: [String: Any] {
        return timedColor()
    }
    
    // Generate a message, used as the payload for sendMessage.
    //
    var message: [String: Any] {
        return timedColor()
    }
    
    // Generate a message, used as the payload for sendMessage.
    //
    var testLocation: CLLocation? {
        return CLLocation(latitude: testLat, longitude: testLong)
    }
    
    // Generate a message, used as the payload for sendMessageData.
    //
    var messageData: Data {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: timedColor(), requiringSecureCoding: false)
        guard let timedColor = data else { fatalError("Failed to archive a timedColor dictionary!") }
        return timedColor
    }
    
    // Generate a complication info dictionary, used as the payload for transferCurrentComplicationUserInfo.
    //
    var currentComplicationInfo: [String: Any] {
        var complicationInfo = timedColor()
        complicationInfo[PayloadKey.isCurrentComplicationInfo] = true
        return complicationInfo
    }
}
