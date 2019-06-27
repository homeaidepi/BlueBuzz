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
    
    @IBOutlet weak var statusGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!
    @IBOutlet var commandButton: WKInterfaceButton!
    @IBOutlet var mapObject: WKInterfaceMap!

    // Retain the controllers so that we don't have to reload root controllers for every switch.
    //
    static var instances = [MainInterfaceController]()
    private var command: Command!
    
    private var locationManager: CLLocationManager = CLLocationManager()
    private var mapLocation: CLLocationCoordinate2D?
    
    // Context == nil: the fist-time loading, load pages with reloadRootController then
    // Context != nil: Loading the pages, save the controller instances so that we can
    // switch pages more smoothly.
    //
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestLocation()
        
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
        
        let currentLocation = locations[0]
        let lat = currentLocation.coordinate.latitude
        let long = currentLocation.coordinate.longitude
        
        self.mapLocation = CLLocationCoordinate2DMake(lat, long)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        
        let region = MKCoordinateRegion(center: self.mapLocation!, span: span)
        self.mapObject.setRegion(region)
        
        mapObject.addAnnotation(self.mapLocation!,
                                with: .red)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    @objc
    func appDidEnterBackground(_ notification: Notification) {
        if (WCSession.default.isReachable) {
            statusLabel.setText("Device connected.")
            WKInterfaceDevice.current().play(.success)
        }
        else {
            statusLabel.setText("Device disconnected.")
            WKInterfaceDevice.current().play(.failure)
        }
        print("App moved to background!")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func willActivate() {
        super.willActivate()
        guard command != nil else { return } // For first-time loading do nothing.
        
        // For .updateAppContext, retrieve the receieved app context if any and update the UI.
        // For .transferFile and .transferUserInfo, log the outstanding transfers if any.
        //
//        if command == .updateAppContext {
//            let timedColor = WCSession.default.receivedApplicationContext
//            if timedColor.isEmpty == false {
//                var commandStatus = CommandStatus(command: command, phrase: .received)
//                commandStatus.timedColor = TimedColor(timedColor)
//                updateUI(with: commandStatus)
//            }
        //} else
        if command == .updateAppConnection {
            let newRed = CGFloat(70)/255
            let newGreen = CGFloat(107)/255
            let newBlue = CGFloat(176)/255
            
            let ibmBlueColor = UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
            
            var commandStatus = CommandStatus(command: command, phrase: .received)
            commandStatus.timedColor = TimedColor(ibmBlueColor)
            updateUI(with: commandStatus)
            
        } //else
//            if command == .transferFile {
//            let transferCount = WCSession.default.outstandingFileTransfers.count
//            if transferCount > 0 {
//                let commandStatus = CommandStatus(command: .transferFile, phrase: .finished)
//                logOutstandingTransfers(for: commandStatus, outstandingCount: transferCount)
//            }
//        } else if command == .transferUserInfo {
//            let transferCount = WCSession.default.outstandingUserInfoTransfers.count
//            if transferCount > 0 {
//                let commandStatus = CommandStatus(command: .transferUserInfo, phrase: .finished)
//                logOutstandingTransfers(for: commandStatus, outstandingCount: transferCount)
//            }
//        }
        
        // Update the status group background color.
        //
        //if command != .transferFile && command != .transferUserInfo {
            statusGroup.setBackgroundColor(.black)
        //}
    }
    
    // Load paged-based UI.
    // If a current context is specified, use the timed color it provided.
    //
    private func reloadRootController(with currentContext: CommandStatus? = nil) {
        //let commands: [Command] = [.updateAppContext, .sendMessage, .sendMessageData,
        //                           .transferFile, .transferUserInfo,
        //                           .transferCurrentComplicationUserInfo]
        let commands: [Command] = [.updateAppConnection, .sendMessage]
        var contexts = [CommandStatus]()
        for aCommand in commands {
            var commandStatus = CommandStatus(command: aCommand, phrase: .finished)
            
            if let currentContext = currentContext, aCommand == currentContext.command {
                commandStatus.phrase = currentContext.phrase
                commandStatus.timedColor = currentContext.timedColor
            }
            contexts.append(commandStatus)
        }
        
        let names = Array(repeating: ControllerID.mainInterfaceController, count: contexts.count)
        WKInterfaceController.reloadRootControllers(withNames: names, contexts: contexts)
    }
    
    // .dataDidFlow notification handler. Update the UI based on the command status.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? CommandStatus else { return }
        
        // If the data is from current channel, simple update color and time stamp, then return.
        //
        if commandStatus.command == command {
            updateUI(with: commandStatus, errorMessage: commandStatus.errorMessage)
            return
        }
        
        // Move the screen to the page matching the data channel, then update the color and time stamp.
        //
        if let index = type(of: self).instances.firstIndex(where: { $0.command == commandStatus.command }) {
            let controller = MainInterfaceController.instances[index]
            controller.becomeCurrentPage()
            controller.updateUI(with: commandStatus, errorMessage: commandStatus.errorMessage)
        }
    }

    // .activationDidComplete notification handler.
    //
    @objc
    func activationDidComplete(_ notification: Notification) {
        print("\(#function): activationState:\(WCSession.default.activationState.rawValue)")
    }
    
    // .reachabilityDidChange notification handler.
    //
    @objc
    func reachabilityDidChange(_ notification: Notification) {
        if (WCSession.default.isReachable) {
            statusLabel.setText("Device connected.")
            WKInterfaceDevice.current().play(.success)
        }
        else {
            statusLabel.setText("Device disconnected.")
            WKInterfaceDevice.current().play(.failure)
        }
        
        print("\(#function): isReachable:\(WCSession.default.isReachable)")
    }
    
    // Do the command associated with the current page.
    //
    @IBAction func commandAction() {
        guard let command = command else { return }
        
        switch command {
        //case .updateAppContext: updateAppContext(appContext)
        case .updateAppConnection: updateAppConnection(appConnection)
        case .sendMessage: sendMessage(message)
        case .sendMessageData: sendMessageData(messageData)
        //case .transferUserInfo: transferUserInfo(userInfo)
        //case .transferFile: transferFile(file, metadata: fileMetaData)
        //case .transferCurrentComplicationUserInfo: transferCurrentComplicationUserInfo(currentComplicationInfo)
    }
    
    // Show outstanding transfer UI for .transferFile and .transferUserInfo.
    //
    //@IBAction func statusAction() {
//        if command == .transferFile {
//            presentController(withName: ControllerID.fileTransfersController, context: command)
//        } else if command == .transferUserInfo {
//            presentController(withName: ControllerID.userInfoTransfersController, context: command)
        }
    //}
}

    extension MainInterfaceController { // MARK: - Update status view.
    
    // Update the user interface with the command status.
    // Note that there isn't a timed color when the interface controller is initially loaded.
    //
    private func updateUI(with commandStatus: CommandStatus, errorMessage: String? = nil) {
        guard let timedColor = commandStatus.timedColor else {
            statusLabel.setText("")
            commandButton.setTitle(commandStatus.command.rawValue)
            return
        }
        
        let title = NSAttributedString(string: commandStatus.command.rawValue,
                                       attributes: [.foregroundColor: timedColor.color])
        commandButton.setAttributedTitle(title)
        statusLabel.setTextColor(timedColor.color)
        
        // If there is an error, show the message and return.
        //
        if let errorMessage = errorMessage {
            statusLabel.setText("! \(errorMessage)")
            return
        }
        
        // Observe the file transfer if it's phrase is "transferring".
        // Unobserve a file transfer if it's phrase is "finished".
        //
//        if let fileTransfer = commandStatus.fileTransfer, commandStatus.command == .transferFile {
//            if commandStatus.phrase == .finished {
//                fileTransferObservers.unobserve(fileTransfer)
//            } else if commandStatus.phrase == .transferring {
//                fileTransferObservers.observe(fileTransfer) { _ in
//                    self.logProgress(for: commandStatus)
//                }
//            }
//        }
        
        // Log the outstanding file transfers if any.
        //
//        if commandStatus.command == .transferFile {
//            let transferCount = WCSession.default.outstandingFileTransfers.count
//            if transferCount > 0 {
//                return logOutstandingTransfers(for: commandStatus, outstandingCount: transferCount)
//            }
//        }
        
        // Log the outstanding UserInfo transfers if any.
        //
//        if commandStatus.command == .transferUserInfo {
//            let transferCount = WCSession.default.outstandingUserInfoTransfers.count
//            if transferCount > 0 {
//                return logOutstandingTransfers(for: commandStatus, outstandingCount: transferCount)
//            }
//        }
        if commandStatus.command == .updateAppConnection
        {
            if (WCSession.default.isReachable) {
                statusLabel.setText("Device connected.")
                WKInterfaceDevice.current().play(.success)
            }
            else {
                statusLabel.setText("Device disconnected.")
                WKInterfaceDevice.current().play(.failure)
            }
        } else {
            statusLabel.setText( commandStatus.phrase.rawValue + " at\n" + timedColor.timeStamp)
        }
    }
    
    // Log the outstanding transfer information if any.
    //
    private func logOutstandingTransfers(for commandStatus: CommandStatus, outstandingCount: Int) {
        if commandStatus.phrase == .transferring {
            var text = commandStatus.phrase.rawValue + " at\n" + commandStatus.timedColor!.timeStamp
            text += "\nOutstanding: \(outstandingCount)\n Tap to view"
            return statusLabel.setText(text)
        }
        
        if commandStatus.phrase == .finished {
            return statusLabel.setText("Outstanding: \(outstandingCount)\n Tap to view")
        }
    }
    
    // Log the file transfer progress. The command status is captured at the momment when
    // the file transfer is observed.
    //
    private func logProgress(for commandStatus: CommandStatus) {
        guard let fileTransfer = commandStatus.fileTransfer else { return }
        
        let fileName = fileTransfer.file.fileURL.lastPathComponent
        let progress = fileTransfer.progress.localizedDescription ?? "No progress"
        statusLabel.setText(commandStatus.phrase.rawValue + "\n" + fileName + "\n" + progress)
    }
}
