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
    @IBOutlet weak var
    containerConstraint:
    NSLayoutConstraint!
    
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
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        getWelcomeMessage()
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
    }
    
    func getWelcomeMessage()
    {
        var message: String = "Welcome to Blue Buzz..."
        if (Variables.welcomeMessage.count < 30) {
            sessionDelegater.getChangeLogByVersion(onSuccess: { (JSON) in
                
                message = JSON[messageKey] as? String ?? emptyMessage
                
                Variables.welcomeMessage = message
                DispatchQueue.main.async {
                    self.logView.attributedText =  Variables.welcomeMessage.html2Attributed
                }
                
            }) { (error, params) in
                if let err = error {
                   message = "\nError: " + err.localizedDescription
                }
                message += "\nParameters passed are: " + String(describing:params)
                
                DispatchQueue.main.async {
                    self.logView.attributedText = message.html2Attributed
                    
                    self.logView.textColor = UIColor(white: 1, alpha: 1)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pageLabel!.text = dataObject
        
        switch (pageLabel.text) {
            case SessionPages.Settings.rawValue:
                reachableLabel.isHidden = false
                clearButton.setTitle("Reset", for: .normal)
                logView.isHidden = true
                tableContainerView.isHidden = true
                settingsPanel.isHidden = false
                secondsBeforeCheckingLocationValue.value = Float(sessionDelegater.getSecondsBeforeCheckingLocation())
                secondsBeforeCheckingDistanceValue.value =
                    Float(sessionDelegater.getSecondsBeforeCheckingDistance())
                distanceBeforeNotifyingValue.value = Float(sessionDelegater.getDistanceBeforeNotifying())
                logView.attributedText = ("").html2Attributed
        case SessionPages.LogView.rawValue:
            settingsPanel.isHidden = true
            tableContainerView.isHidden = false
            reachableLabel.isHidden = false
            clearButton.setTitle("Clear", for: .normal)
            logView.isHidden = false
            logView.attributedText = Variables.logHistory
            
            //fix for container being offscreen
            containerConstraint.constant = self.view.frame.size.height - 70
            
        default :
            settingsPanel.isHidden = true
            tableContainerView.isHidden = true
            reachableLabel.isHidden = true
            clearButton.setTitle("", for: .normal)
            logView.isHidden = false
            logView.attributedText = Variables.welcomeMessage.html2Attributed
            logView.scrollRangeToVisible(NSMakeRange(0, 1))
        }
        
        self.updateReachabilityColor()
    }
    
    // Implement the round corners on the top.
    // Do this here because everything should have been laid out at this moment.
    //
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Append the message to the end of the text view and make sure it is visiable.
    //
    private func log(_ message: String) {
        if (pageLabel.text == SessionPages.LogView.rawValue) {
            
            let format = "#{{message}} #{{newLine}}"
            let attributedMessage = NSAttributedString(format: format,
                                             mapping: ["message": message,
                                                       "newLine": "\n"])

            Variables.logHistory.append(attributedMessage)
            
            logView.attributedText = Variables.logHistory
            logView.scrollRangeToVisible(NSMakeRange(0, 1))
        }
    }
    
    @IBAction func clear(_ sender: UIButton) {
        if (logView.isHidden == false) {
            Variables.logHistory = NSMutableAttributedString()
            logView.attributedText = Variables.logHistory
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
        }
        else {
            log("Device: \(deviceId) missing lat,long at: \(timedColor.timeStamp)")
        }
        
        updateReachabilityColor()
    }
}
