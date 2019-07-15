/*
 See LICENSE folder for this sample’s licensing information.
 Abstract:
 The main interface controller of the WatchKit extension.
 */

import Foundation
import WatchKit
import WatchConnectivity
import CoreLocation
import UserNotifications

// identifier: page Interface Controller identifier.
// Context: page context, a string used as the action button title.
//
struct ControllerID {
    static let mainInterfaceController = "MainInterfaceController"
}

class MainInterfaceController: WKInterfaceController, CLLocationManagerDelegate, TestDataProvider, SessionCommands {

    @IBOutlet weak var statusGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!
    @IBOutlet var commandButton: WKInterfaceButton!
    @IBOutlet var mapObject: WKInterfaceMap!

    // Retain the controllers so that we don't have to reload root controllers for every switch.
    //
    static var instances = [MainInterfaceController]()
    
    private var command: Command?
    private var locationManager: CLLocationManager?
    private var location: CLLocation?
    private var mapLocation: CLLocationCoordinate2D?
    private var lastUpdatedLocationDateTime: Date?
    
    let myDelegate = WKExtension.shared().delegate as! ExtensionDelegate

    // Context == nil: the fist-time loading, load pages with reloadRootController then
    // Context != nil: Loading the pages, save the controller instances so that we can
    // switch pages more smoothly.
    //
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let context = context as? CommandStatus {
            command = context.command
            updateUI(with: context)
            type(of: self).instances.append(self)
        } else {
            statusLabel.setText("Connecting...")
            reloadRootController()
        }
        
        // Install notification observer.
        //
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).activationDidComplete(_:)),
            name: .activationDidComplete, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).reachabilityDidChange(_:)),
            name: .reachabilityDidChange, object: nil
        )
        
        initLocationManager()
        notifyUI();
    }
    
    func initLocationManager()
    {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.requestLocation()
        //locationManager?.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if (SessionDelegater().checkLastUpdatedLocationDateTime(lastUpdatedLocationDateTime: lastUpdatedLocationDateTime) == false) {
            return
        }
        
        //Step 1 get current location from locationManager return result
        let currentLocation = locations[0]
        let lat = currentLocation.coordinate.latitude
        let long = currentLocation.coordinate.longitude
        
        //set the current location in the extension delegate
        let instanceId = myDelegate.setCurrentLocation(location: currentLocation)
        
        //step 2 assign local variables
        self.location = currentLocation
        self.mapLocation = CLLocationCoordinate2DMake(lat, long)
        
        //step 3 define map objects
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: self.mapLocation!, span: span)
        
        //step 4 locate the region and set the pin in the map
        self.mapObject.setRegion(region)
        mapObject.addAnnotation(self.mapLocation!, with: .purple)
        
        //send the companion phone app the location data if in range
        var commandStatus = CommandStatus(command: .sendMessageData,
                                           phrase: .sent,
                                           latitude: currentLocation.coordinate.latitude,
                                           longitude: currentLocation.coordinate.longitude,
                                           instanceId: instanceId,
                                           timedColor: TimedColor(ibmBlueColor),
                                           errorMessage: emptyError)
        
        do {
            if (myDelegate.postLocationByInstanceId(commandStatus: commandStatus, deviceId: "watchos")) {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                lastUpdatedLocationDateTime = Date()
                
                let data = try JSONEncoder().encode(commandStatus)
                
                //let jsonString = String(data: data, encoding: .utf8)!
                //print(jsonString)
                
                WCSession.default.sendMessageData(data, replyHandler: {
                  replyHandler in
                    },
                  errorHandler: { error in
                    commandStatus.errorMessage = error.localizedDescription
                })
            }
        } catch {
            commandStatus.errorMessage = "Send Location Error"
        }
        
        updateUI(with: commandStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let description = error.localizedDescription
        print(description)
        
        if (description.contains("Code: 0") == false) {
            _ = myDelegate.setCurrentLocation(location: emptyLocation)
            myDelegate.scheduleNotifications()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            locationManager?.requestLocation()
        }
    }
    
    func applicationDidEnterBackground() {
        return
    }
    
    func applicationDidBecomeActive() {
        notifyUI()
        return
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        print("application will resign active")
    }
    
//    @objc private func deinitLocationManager() {
//        locationManager = nil
//    }
    
    deinit {
        //NotificationCenter.default.removeObserver(self)
        //cant deinit the location manager as we run in the background
//        self.performSelector(onMainThread: #selector(deinitLocationManager), with: nil, waitUntilDone: true)
    }
    
    override func willActivate() {
        super.willActivate()

        locationManager?.requestLocation()
        
        // Update the status group background color.
        //
        statusGroup.setBackgroundColor(.black)

    }
    
    // Load paged-based UI.
    // If a current context is specified, use the timed color it provided.
    //
    private func reloadRootController(with currentContext: CommandStatus? = nil) {
        //let commands: [Command] = [.updateAppConnection, .sendMessage, .sendMessageData]
        let commands: [Command] = [.sendMessageData]
        
        var contexts = [CommandStatus]()
        for aCommand in commands {
            var command = CommandStatus(command: aCommand,
                                         phrase: .finished,
                                         latitude: emptyDegrees,
                                         longitude: emptyDegrees,
                                         instanceId: emptyInstanceIdentifier,
                                         timedColor: defaultColor,
                                         errorMessage: emptyError)
            
            if let currentContext = currentContext, aCommand == currentContext.command {
                command.phrase = currentContext.phrase
                command.timedColor = currentContext.timedColor
                command.latitude = currentContext.latitude
                command.longitude = currentContext.longitude
            }
            contexts.append(command)
        }
        
        let names = Array(repeating: ControllerID.mainInterfaceController, count: contexts.count)
        WKInterfaceController.reloadRootControllers(withNames: names, contexts: contexts)
    }
    
    // .dataDidFlow notification handler. Update the UI based on the command status.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? CommandStatus else { return }
        
        // Move the screen to the page matching the data channel, then update the color and time stamp.
        //
        if let index = type(of: self).instances.firstIndex(where: { $0.command == commandStatus.command }) {
            let controller = MainInterfaceController.instances[index]
            controller.becomeCurrentPage()
            controller.updateUI(with: commandStatus)
        }
    }
    // .activationDidComplete notification handler.
    //
    @objc
    func activationDidComplete(_ notification: Notification) {
        //print("\(#function): activationState:\(WCSession.default.activationState.rawValue)")
    }
    
    // .reachabilityDidChange notification handler.
    //
    @objc
    func reachabilityDidChange(_ notification: Notification) {
        notifyUI();
        //print("\(#function): isReachable:\(WCSession.default.isReachable)")
    }
 
    // Do the command associated with the current page.
    //
    @IBAction func commandAction() {
        guard let command = command
        else {
            return
        }
        
        switch command {
        //case .updateAppConnection: updateAppConnection(appConnection)
        //case .sendMessage: sendMessage(message)
        //case .sendMessageData: sendMessageData(messageData, location: location, instanceId: instanceId)
        case .sendMessageData:  locationManager?.requestLocation()
        }
    }
}

    extension MainInterfaceController { // MARK: - Update status view.
    
    //Play haptic notifications to the user and display some updated data
    //
    private func notifyUI() {
        if (WCSession.default.isReachable) {
            statusLabel.setText("Device paired... \n Sending location.")
            WKInterfaceDevice.current().play(.success)
        }
        else {
            statusLabel.setText("Device not paired. Please pair iPhone.")
            WKInterfaceDevice.current().play(.failure)
            WKInterfaceDevice.current().play(.notification)
        }
    }
    
    // Update the user interface with the command status.
    // Note that there isn't a timed color when the interface controller is initially loaded.
    //
    private func updateUI(with commandStatus: CommandStatus) {
        let timedColor = commandStatus.timedColor
        let title = NSAttributedString(string: commandStatus.command.rawValue,
                                       attributes: [.foregroundColor: ibmBlueColor])
        commandButton.setAttributedTitle(title)
        
        // If there is an error, show the message and return.
        //
        if commandStatus.errorMessage != "" {
            statusLabel.setText("! \(commandStatus.errorMessage)")
        } else {
            statusLabel.setText(commandStatus.phrase.rawValue + " at\n" + timedColor.timeStamp)
        }
        statusLabel.setTextColor(timedColor.color.color)
        
        print("id: " + commandStatus.instanceId)
    }
}
