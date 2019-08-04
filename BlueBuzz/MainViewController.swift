/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller of the iOS app.
*/

import UIKit
import WatchConnectivity
import UserNotifications

class MainViewController: UIViewController {
        
    @IBOutlet weak var reachableLabel: UILabel!
    @IBOutlet weak var tableContainerView: UIView!
    @IBOutlet weak var logView: UITextView!
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var tablePlaceholderView: UIView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var secondsBeforeCheckingLocationValue: UISlider!
    @IBOutlet weak var secondsBeforeCheckingDistanceValue: UISlider!
    @IBOutlet weak var distanceBeforeNotifyingValue: UISlider!
    @IBOutlet weak var secondsBeforeCheckingLocationLabel: UILabel!
    @IBOutlet weak var secondsBeforeCheckingDistanceLabel: UILabel!
    @IBOutlet weak var distanceBeforeNotifyingLabel: UILabel!
    @IBOutlet weak var settingsPanel: UIStackView!
    
    var welcomeMessage: String = "Welcome to Blue Buzz..."
    var dataObject: String = ""
    
    @IBAction func secondsBeforeCheckingLocationValueChanged(sender: UISlider) {
        let currentValue = Int(secondsBeforeCheckingLocationValue.value)
        
        secondsBeforeCheckingLocationLabel.text = "\(currentValue) Seconds Before Checking Location"
        
        //print("Slider changing to \(currentValue) ?")
        sessionDelegater.saveSecondsBeforeCheckingLocation(secondsBeforeCheckingLocation: currentValue)
        
        syncSettings()
    }
    
    @IBAction func secondsBeforeCheckingDistanceValueChanged(sender: UISlider) {
        let currentValue = Int(secondsBeforeCheckingDistanceValue.value)
        
        secondsBeforeCheckingDistanceLabel.text = "\(currentValue) Seconds Before Checking Distance"
        
        //print("Slider changing to \(currentValue) ?")
        sessionDelegater.saveSecondsBeforeCheckingDistance(secondsBeforeCheckingDistance: currentValue)
        
        syncSettings()
    }
    
    @IBAction func distanceBeforeNotifyingValueChanged(sender: UISlider) {
        let currentValue = Double(distanceBeforeNotifyingValue.value).rounded()
        
        distanceBeforeNotifyingLabel.text = "\(currentValue) Feet Before Sending Alert "
        //print("Slider changing to \(currentValue) ?")
        sessionDelegater.saveDistanceBeforeNotifying(distanceBeforeNotifying: currentValue)
        
        syncSettings()
    }
    
    func syncSettings()
    {
        let settings = sessionDelegater.getSettings()
        
        do {
            var isReachable = false
            if WCSession.default.activationState == .activated {
                isReachable = WCSession.default.isReachable
            }
            
            if (isReachable == false)
            {
                WCSession.default.delegate = sessionDelegater
                WCSession.default.activate()
            }
            
            print("Reachable: \(isReachable)")
            
            try WCSession.default.updateApplicationContext(settings)
        } catch {
            print("Settings Sync Error")
        }
    }
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        WCSession.default.delegate = sessionDelegater
        WCSession.default.activate()
        
        getWelcomeMessage()
    }
    
    func getWelcomeMessage()
    {
        sessionDelegater.getChangeLogByVersion(onSuccess: { (JSON) in
            
            let message = JSON[messageKey] as? String ?? emptyMessage
            
            self.welcomeMessage = message
            
            DispatchQueue.main.async {
                self.logView.text = self.welcomeMessage
            }
        }) { (error, params) in
            if let err = error {
               self.welcomeMessage = "\nError: " + err.localizedDescription
            }
            self.welcomeMessage += "\nParameters passed are: " + String(describing:params)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pageLabel!.text = dataObject
        
        if (pageLabel.text == SessionPages.Settings.rawValue) {
            reachableLabel.isHidden = false
            clearButton.setTitle("Reset", for: .normal)
            logView.isHidden = true
            tableContainerView.isHidden = true
            settingsPanel.isHidden = false
            secondsBeforeCheckingLocationValue.value = Float(sessionDelegater.getSecondsBeforeCheckingLocation())
            secondsBeforeCheckingDistanceValue.value =
                Float(sessionDelegater.getSecondsBeforeCheckingDistance())
            distanceBeforeNotifyingValue.value = Float(sessionDelegater.getDistanceBeforeNotifying())
        } else if (pageLabel.text == SessionPages.LogView.rawValue) {
            settingsPanel.isHidden = true
            tableContainerView.isHidden = false
            reachableLabel.isHidden = false
            clearButton.setTitle("Clear", for: .normal)
            logView.isHidden = false
        } else {
            settingsPanel.isHidden = true
            tableContainerView.isHidden = true
            reachableLabel.isHidden = true
            clearButton.setTitle("", for: .normal)
            logView.isHidden = false
            logView.text = welcomeMessage
        }
        
        self.updateReachabilityColor()
    }
    
    // Implement the round corners on the top.
    // Do this here because everything should have been laid out at this moment.
    //
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        if (tableContainerView.isHidden == false) {
//
//            let layer = CALayer()
//            layer.shadowOpacity = 1.0
//            layer.shadowOffset = CGSize(width: 0, height: 1)
//
//            // Make sure the shadow is outside of the bottom of the screen.
//            //
//            var rect = self.tableContainerView.bounds
//
//            if #available(iOS 11.0, *) {
//                rect.size.height += view.safeAreaLayoutGuide.layoutFrame.size.height
//            }
//
//            let path = UIBezierPath(roundedRect: rect,
//                                    byRoundingCorners: [.topRight, .topLeft],
//                                    cornerRadii: CGSize(width: 10, height: 10))
//            let shapeLayer = CAShapeLayer()
//            shapeLayer.path = path.cgPath
//            shapeLayer.fillColor = UIColor.clear.cgColor
//            shapeLayer.backgroundColor = UIColor.clear.cgColor
//            
//            
//            layer.addSublayer(shapeLayer)
//
//            tableContainerView.layer.addSublayer(layer)
//            tablePlaceholderView.layer.zPosition = layer.zPosition + 1
//        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Append the message to the end of the text view and make sure it is visiable.
    //
    private func log(_ message: String) {
        if (logView.isHidden == false) {
            if (logView.text != "") {
                logView.text = logView.text! + "\n"
            }
            logView.text = logView.text! + message
            logView.scrollRangeToVisible(NSRange(location: logView.text.count, length: 1))
        }
    }
    
    @IBAction func clear(_ sender: UIButton) {
        if (logView.isHidden == false) {
            logView.text = ""
        } else {
            secondsBeforeCheckingLocationValue.value = 45
            secondsBeforeCheckingDistanceValue.value = 60
            distanceBeforeNotifyingValue.value = 100
        sessionDelegater.saveSecondsBeforeCheckingLocation(secondsBeforeCheckingLocation: Int(secondsBeforeCheckingLocationValue!.value))
        sessionDelegater.saveSecondsBeforeCheckingDistance(secondsBeforeCheckingDistance: Int(secondsBeforeCheckingDistanceValue!.value))
        sessionDelegater.saveDistanceBeforeNotifying(distanceBeforeNotifying: Double(distanceBeforeNotifyingValue!.value))
            
            syncSettings()
        }
    }
    
    private func updateReachabilityColor() {
        // WCSession.isReachable triggers a warning if the session is not activated.
        //
        var isReachable = false
        if WCSession.default.activationState == .activated {
            isReachable = WCSession.default.isReachable
        }
        
        reachableLabel.textColor = isReachable ? .green : .red
        reachableLabel.text = isReachable ? "Connected" : "Disconnected"
        
        if (isReachable == false) {
            return //TODO Local notifications for ios
        } else {
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
        
    }
    
    // .activationDidComplete notification handler.
    //
    @objc
    func activationDidComplete(_ notification: Notification) {
        updateReachabilityColor()
    }
    
    // .reachabilityDidChange notification handler.
    //
    @objc
    func reachabilityDidChange(_ notification: Notification) {
        updateReachabilityColor()
    }
    
    // .dataDidFlow notification handler.
    // Update the UI based on the userInfo dictionary of the notification.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
        
        guard let commandStatus = notification.object as? CommandStatus else { return }
        
        //TODO May be a good reference for page settings
//        defer { noteLabel.isHidden = logView.text.isEmpty ? false: true }
//
        // If an error occurs, show the error message and returns.
        //
        if commandStatus.errorMessage.count > 0 {
            log("\(commandStatus.command.rawValue): \(commandStatus.errorMessage)")
            return
        }
        
        let timedColor = commandStatus.timedColor
        let lat = commandStatus.latitude
        let long = commandStatus.longitude
        let instanceId = commandStatus.instanceId
        let deviceId = commandStatus.deviceId
        
        if (instanceId != emptyInstanceIdentifier)
        {
            //todo dont need to save every message. Only once.
            sessionDelegater.saveInstanceIdentifier(instanceId: instanceId)
        }
        
        //log the messageData i.e location to the screen else show command
        //
        if (lat != emptyDegrees && long != emptyDegrees)
        {
            if (logView.text.contains("id")) {
                log("\(deviceId) sent at: \(timedColor.timeStamp)")
            } else {
                log("id:\(instanceId.prefix(20))\n\(deviceId) sent at: \(timedColor.timeStamp)")
            }
//        log("{id:\(instanceId), location: { lat:\(lat), long:\(long) }, <b> deviceId: \(deviceId)</b>,  secCheckLocation:\(sessionDelegater.getSecondsBeforeCheckingLocation()), secCheckDistance:\(sessionDelegater.getSecondsBeforeCheckingDistance()), distanceBeforeNotifying:\(sessionDelegater.getDistanceBeforeNotifying()), command:\(commandStatus.command.rawValue), phrase:\(commandStatus.phrase.rawValue), timeStamp:\(timedColor.timeStamp)}")
        }
        else {
            log("Device: \(deviceId) missing lat,long at: \(timedColor.timeStamp)")
        }
        
        updateReachabilityColor()
    }
}
