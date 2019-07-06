/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main interface controller of the WatchKit extension.
*/

import Foundation
import WatchKit
import WatchConnectivity
import CoreLocation

// identifier: page Interface Controller identifier.
// Context: page context, a string used as the action button title.
//
struct ControllerID {
    static let mainInterfaceController = "MainInterfaceController"
}

class MainInterfaceController: WKInterfaceController, CLLocationManagerDelegate, TestDataProvider, SessionCommands {
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    // Retain the controllers so that we don't have to reload root controllers for every switch.
    //
    private static var instances = [MainInterfaceController]()
    
    private var command: Command?
    
    @IBOutlet weak var statusGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!
    @IBOutlet var commandButton: WKInterfaceButton!
    @IBOutlet var mapObject: WKInterfaceMap!
    
    @IBAction func commandAction() {
        guard let command = command
            else {
                return
        }
        
        switch command {
        case .updateAppConnection: updateAppConnection(appConnection)
        case .sendMessage: sendMessage(message)
        case .sendMessageData: sendMessageData(messageData, location: location)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Context == nil: the fist-time loading, load pages with reloadRootController then
    // Context != nil: Loading the pages, save the controller instances so that we can
    // switch pages more smoothly.
    //
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Activate the session asynchronously as early as possible.
        // In the case of being background launched with a task, this may save some background runtime budget.
        //
        WCSession.default.delegate = sessionDelegater
        WCSession.default.activate()
        
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
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).appDidEnterBackground(_:)),
            name: .appDidEnterBackground, object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //Step 1 get current location from locationManager return result
        let currentLocation = locations[0]
        let lat = currentLocation.coordinate.latitude
        let long = currentLocation.coordinate.longitude
        
        //step 2 assign local variables
        self.location = currentLocation
        self.mapLocation = CLLocationCoordinate2DMake(lat, long)
        
        //step 3 define map objects
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: self.mapLocation!, span: span)
        
        //step 4 locate the region and set the pin in the map
        self.mapObject.setRegion(region)
        mapObject.addAnnotation(self.mapLocation!, with: .purple)
        
        //update status labels
        //i+=1
        //statusLabel.setText("i:\(i) Lat-\(lat):Long-\(long)")
        
        //send the companion phone app the location data if in range
        let commandStatus = CommandMessage(command: .sendMessageData,
                                          phrase: .sent,
                                          latitude: currentLocation.coordinate.latitude,
                                          longitude: currentLocation.coordinate.longitude,
                                          timedColor: defaultColor,
                                          errorMessage: "")
        
        do {
            let data = try JSONEncoder().encode(commandStatus)
            
            let jsonString = String(data: data, encoding: .utf8)!
            print(jsonString)
            
            WCSession.default.sendMessageData(data, replyHandler: { replyHandler in
            }, errorHandler: { error in
            self.statusLabel.setText("error")})
        } catch {
            self.statusLabel.setText("Send Message Data")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusLabel.setText(error.localizedDescription)
    }
    
    }
    
    override func willActivate() {
        super.willActivate()
        
        // For .updateAppConnection, retrieve the receieved app context if any and update the UI.
        if command == .updateAppConnection {
            let commandStatus = CommandMessage(command: .updateAppConnection,
                                              phrase: .received,
                                              latitude: emptyDegrees,
                                              longitude: emptyDegrees,
                                              timedColor: defaultColor,
                                              errorMessage: emptyError)
            updateUI(with: commandStatus)
        }

        // Update the status group background color.
        //
        statusGroup.setBackgroundColor(.black)
        
        var contexts = [CommandMessage]()
        for aCommand in commands {
            var command = CommandMessage(command: aCommand,
                                        phrase: .finished,
                                        latitude: emptyDegrees,
                                        longitude: emptyDegrees,
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
    }
    
    func requestLocationFromDelegate()
    {
        let watchDelegate = WKExtension.shared().delegate as? ExtensionDelegate
        watchDelegate?.requestLocation()
    }
    
    // .dataDidFlow notification handler. Update the UI based on the command status.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? CommandMessage else { return }
        
        // Move the screen to the page matching the data channel, then update the color and time stamp.
        //
        if let index = type(of: self).instances.firstIndex(where: { $0.command == commandStatus.command }) {
            let controller = MainInterfaceController.instances[index]
            controller.becomeCurrentPage()
            controller.updateUI(with: commandStatus)
        }
    }
    
    @objc
    func applicationDidEnterBackground(_ notification: Notification)
    {
        //here if need be
    }
    
    @objc
    func activationDidComplete(_ notification: Notification) {
        //print("\(#function): activationState:\(WCSession.default.activationState.rawValue)")
    }
    
    @objc
    func reachabilityDidChange(_ notification: Notification) {
        //print("\(#function): isReachable:\(WCSession.default.isReachable)")
    }
    
    // Load paged-based UI.
    // If a current context is specified, use the timed color it provided.
    //
    private func reloadRootController(with currentContext: CommandStatus? = nil) {
        let commands: [Command] = [.updateAppConnection, .sendMessage, .sendMessageData]
        
        var contexts = [CommandStatus]()
        for aCommand in commands {
            var command = CommandStatus(command: aCommand,
                                        phrase: .finished,
                                        latitude: emptyDegrees,
                                        longitude: emptyDegrees,
                                        timedColor: defaultColor,
                                        errorMessage: emptyError)
            
            if let currentContext = currentContext, aCommand == currentContext.command {
                command.phrase = currentContext.phrase
                command.timedColor = currentContext.timedColor
            }
            contexts.append(command)
        }
        
        let names = Array(repeating: ControllerID.mainInterfaceController, count: contexts.count)
        WKInterfaceController.reloadRootControllers(withNames: names, contexts: contexts)
    }
}

extension MainInterfaceController { // MARK: - Update status view.
    
    //Play haptic notifications to the user and display some updated data
    //
    private func notifyUI() {
        if (WCSession.default.isReachable) {
            statusLabel.setText("Device connected.")
            WKInterfaceDevice.current().play(.success)
        }
        else {
            statusLabel.setText("Device disconnected.")
            WKInterfaceDevice.current().play(.failure)
            WKInterfaceDevice.current().play(.notification)
        }
    }
        
    // Update the user interface with the command status.
    // Note that there isn't a timed color when the interface controller is initially loaded.
    //
    private func updateUI(with commandStatus: CommandStatus) {
        
        // If there is an error, show the message and return.
        //
        if commandStatus.errorMessage != "" {
            statusLabel.setText("! \(commandStatus.errorMessage)")
            return
        }
        
        let timedColor = commandStatus.timedColor
        let title = NSAttributedString(string: commandStatus.command.rawValue,
                                       attributes: [.foregroundColor: ibmBlueColor])
        commandButton.setAttributedTitle(title)
        statusLabel.setTextColor(timedColor.color.color)
        
        if commandStatus.command == .updateAppConnection
        {
            notifyUI();
        } else {
            statusLabel.setText(commandStatus.phrase.rawValue + " at\n" + timedColor.timeStamp)
        }
    }
}
