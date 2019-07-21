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
    @IBOutlet weak var settingsPanel: UIStackView!
    
    var dataObject: String = ""
    
//    private var instanceId: String = ""
//    private var secondsBeforeCheckingLocation: Int = 45
//    private var secondsBeforeCheckingDistance: Int = 60
//    private var distanceBeforeNotifying: Double = 100
    
    @IBAction func secondsBeforeCheckingLocationValueChanged(sender: UISlider) {
        let currentValue = Int(secondsBeforeCheckingLocationValue.value)
        print("Slider changing to \(currentValue) ?")
        sessionDelegater.saveSecondsBeforeCheckingDistance(secondsBeforeCheckingDistance: currentValue)
        let settings = sessionDelegater.getSettings()
        
        do {
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pageLabel!.text = dataObject
        
        if (pageLabel.text == SessionPages.Settings.rawValue) {
            reachableLabel.isHidden = true
            clearButton.isHidden = true
            logView.isHidden = true
            tableContainerView.isHidden = true
            settingsPanel.isHidden = false
            secondsBeforeCheckingLocationValue.value = Float(sessionDelegater.getSecondsBeforeCheckingLocation())
        } else {
            settingsPanel.isHidden = true
            tableContainerView.isHidden = false
            reachableLabel.isHidden = false
            clearButton.isHidden = false
            logView.isHidden = false
        }
        //self.updateReachabilityColor()
    }
    
    // Implement the round corners on the top.
    // Do this here because everything should have been laid out at this moment.
    //
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (pageLabel.text == SessionPages.History.rawValue) {
            let layer = CALayer()
            layer.shadowOpacity = 1.0
            layer.shadowOffset = CGSize(width: 0, height: 1)
            
            // Make sure the shadow is outside of the bottom of the screen.
            //
            let rect = self.tableContainerView.bounds
            
    //        if #available(iOS 11.0, *) {
    //            rect.size.height += view.window!.safeAreaInsets.bottom
    //        }
            
            let path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [.topRight, .topLeft],
                                    cornerRadii: CGSize(width: 10, height: 10))
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = UIColor.white.cgColor
            
            layer.addSublayer(shapeLayer)
            
            tableContainerView.layer.addSublayer(layer)
                tablePlaceholderView.layer.zPosition = layer.zPosition + 1
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Append the message to the end of the text view and make sure it is visiable.
    //
    private func log(_ message: String) {
        logView.text = logView.text! + "\n\n" + message
        logView.scrollRangeToVisible(NSRange(location: logView.text.count, length: 1))
    }
    
    private func updateReachabilityColor() {
        // WCSession.isReachable triggers a warning if the session is not activated.
        //
        var isReachable = false
        if WCSession.default.activationState == .activated {
            isReachable = WCSession.default.isReachable
        }
        reachableLabel.textColor = isReachable ? .green : .red
        reachableLabel.text = isReachable ? "Device Connected" : "Device Disconnected"
        
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

    @IBAction func clear(_ sender: UIButton) {
        logView.text = ""
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
            log("! \(commandStatus.command.rawValue): \(commandStatus.errorMessage)")
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
//        if (lat != emptyDegrees && long != emptyDegrees)
//        {
        log("{id:\(instanceId), location: { lat:\(lat), long:\(long) }, <b> deviceId: \(deviceId)</b>,  secCheckLocation:\(sessionDelegater.getSecondsBeforeCheckingLocation()), secCheckDistance:\(sessionDelegater.getSecondsBeforeCheckingDistance()), distanceBeforeNotifying:\(sessionDelegater.getDistanceBeforeNotifying()), command:\(commandStatus.command.rawValue), phrase:\(commandStatus.phrase.rawValue), timeStamp:\(timedColor.timeStamp)}")
//        }
//        else {
//            log("-> id:\(instanceId) \(commandStatus.command.rawValue): \(commandStatus.phrase.rawValue) at \(timedColor.timeStamp)")
//        }
    }
}
