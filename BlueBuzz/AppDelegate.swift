/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app delegate class of the iOS app.
*/

import UIKit
import WatchConnectivity
import UserNotifications

let CurrentModeKey = "CurrentMode"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Trigger WCSession activation at the early phase of app launching.
        //
        assert(WCSession.isSupported(), "BlueBuzz requires Apple Watch!")
        WCSession.default.delegate = sessionDelegater
        WCSession.default.activate()
        
        // Remind the setup of WatchSettings.sharedContainerID.
        //
        if WatchSettings.sharedContainerID.isEmpty {
            print("Specify a shared container ID for WatchSettings.sharedContainerID to use watch settings!")
        }
        
        registerForPushNotifications()
        sendInstanceIdMessage()
        

        return true
    }
    
    private func sendInstanceIdMessage()
    {
        var instanceId = getInstanceIdentifier()
        // we are going to keep a guid that indicates a unique id or (instance) of this shared connection between watch and phone for the purposes of cloud communication
        //
        if (instanceId == "")
        {
            instanceId = UUID().uuidString
            saveInstanceIdentifier(identifier: instanceId)
        }
        
        let commandStatus = CommandStatus(command: .sendMessage,
                                          phrase: .sent,
                                          latitude: emptyDegrees,
                                          longitude: emptyDegrees,
                                          instanceId: instanceId,
                                          timedColor: defaultColor,
                                          errorMessage: "")
        
        do {
            let data = try JSONEncoder().encode(commandStatus)
            
            //let jsonString = String(data: data, encoding: .utf8)!
            //print(jsonString)
            
            WCSession.default.sendMessageData(data, replyHandler: { replyHandler in
            }, errorHandler: { error in
                print("error")})
        } catch {
            print("Send Message Data")
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
    
    private func saveInstanceIdentifier(identifier: String)
    {
        // Get the standard UserDefaults as "defaults"
        let defaults = UserDefaults.standard
        
        // Save the String to the standard UserDefaults under the key, instanceIdentifierKey
        defaults.set(identifier, forKey: instanceIdentifierKey)
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            // 1. Check if permission granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 1. Convert device token to string
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        // 2. Print device token to use for PNs payloads
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // 1. Print out error if PNs registration not successful
        print("Failed to register for remote notifications with error: \(error)")
    }
}
