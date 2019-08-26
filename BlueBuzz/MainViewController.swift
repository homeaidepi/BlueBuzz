import UIKit
import WatchConnectivity
import UserNotifications

class MainViewController: UIViewController {
        
    @IBOutlet weak var reachableLabel: UILabel!
    @IBOutlet weak var tableContainerView: UIView!
    @IBOutlet weak var logView: UITextView!
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var tablePlaceholderView: UIView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var secondsBeforeCheckingLocationValue: UISlider!
    @IBOutlet weak var secondsBeforeCheckingDistanceValue: UISlider!
    @IBOutlet weak var distanceBeforeNotifyingValue: UISlider!
    @IBOutlet weak var secondsBeforeCheckingLocationLabel: UILabel!
    @IBOutlet weak var secondsBeforeCheckingDistanceLabel: UILabel!
    @IBOutlet weak var distanceBeforeNotifyingLabel: UILabel!
    @IBOutlet weak var scrollViewPanel: UIScrollView!
    @IBOutlet weak var settingsPanel: UIStackView!
    @IBOutlet weak var logoLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBanner: UIStackView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var showBackgroundValue: UISwitch!
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    let myDelegate = UIApplication.shared.delegate as? AppDelegate
    
    var dataObject: String = ""
    
    @IBAction func showBackgroundValueChanged(sender: UISwitch) {
        let showBackgroundValue = sender.isOn
        
        print("Switch changing to \(showBackgroundValue) ?")
        sessionDelegater.saveShowBackground(showBackground: showBackgroundValue)
        
        syncSettings()
        
        showBackground(showBackground: showBackgroundValue)
    }
    
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
    
    func showBackground(showBackground: Bool) {
        Variables.showBackground = showBackground
        background.isHidden = !showBackground
    }
    
    func syncSettings()
    {
        let settings = sessionDelegater.getSettings()
        
        let showBackground = settings[showBackgroundKey] as? Bool ?? true
        
        self.showBackground(showBackground: showBackground)
        
        do {
            var isReachable = false
            if WCSession.default.activationState == .activated {
                isReachable = WCSession.default.isReachable
            }
            
            print("Reachable: \(isReachable)")
            
            try WCSession.default.updateApplicationContext(settings)
        } catch {
            print("Settings Sync Error")
        }
    }
    
    func adjustUiConstraints(size: CGSize) {
        var portrait = false
        
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
        } else {
            print("Portrait")
            portrait = true
        }
        
        if (portrait) {
            //logoLeadingConstraint.constant = size.width / 2 - 50
        } else {
            //logoLeadingConstraint.constant = size.width / 2 - 50
        }
        
        //fix for container being offscreen
        containerTopConstraint.constant = size.height - 70
        
        settingsBottomConstraint.constant  = 31.4
        
        reachableLabel.widthAnchor.constraint(equalToConstant: (size.width / 2) + 31.4).isActive = true
        reachableLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        topBanner.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor,
        constant: 8).isActive = true
        topBanner.heightAnchor.constraint(equalToConstant: 31.4).isActive = true
        topBanner.widthAnchor.constraint(equalToConstant: size.width - 31.4).isActive = true
        topBanner.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 41.3).isActive=true
        topBanner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        logView.widthAnchor.constraint(equalToConstant: size.width - 31.4).isActive = true
        logView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logView.heightAnchor.constraint(equalToConstant: size.height - 31.4).isActive=true
        
        let margins = view.layoutMarginsGuide
        topBanner.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        adjustUiConstraints(size: size)
    }
    
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
        
        syncSettings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pageLabel!.text = dataObject
        
        switch (pageLabel.text) {
            case SessionPages.Welcome.rawValue :
                //print(Variables.welcomeMessage.html2Attributed)
                logView.isHidden = false
                getWelcomeMessage()
                
                pageControl.currentPage = 0
                tableContainerView.isHidden = true
                reachableLabel.isHidden = false
                clearButton.setTitle("", for: .normal)
                scrollViewPanel.isUserInteractionEnabled = false
                settingsPanel.isHidden = true
            case SessionPages.Settings.rawValue:
                logView.isHidden = true
                logView.attributedText = ("").html2Attributed
                settingsPanel.isHidden = false
                pageControl.currentPage = 1
                reachableLabel.isHidden = false
                clearButton.setTitle("Reset", for: .normal)
                scrollViewPanel.isUserInteractionEnabled = true
                tableContainerView.isHidden = true
                setSettingSliders()
            case SessionPages.LogView.rawValue:
                pageControl.currentPage = 2
                getLogHistory()
                settingsPanel.isHidden = true
                scrollViewPanel.isUserInteractionEnabled = false
                tableContainerView.isHidden = false
                reachableLabel.isHidden = false
                clearButton.setTitle("Clear", for: .normal)
                //fix for container being offscreen
                adjustUiConstraints(size: self.view.frame.size)
            default:
                logView.isHidden = true
                pageControl.currentPage = 3
                settingsPanel.isHidden = true
                scrollViewPanel.isUserInteractionEnabled = false
                tableContainerView.isHidden = true
                reachableLabel.isHidden = true
                clearButton.setTitle("", for: .normal)
        }
        
        self.updateReachabilityColor()
        self.showBackground(showBackground: Variables.showBackground)
        self.adjustUiConstraints(size: view.frame.size)
    }
    
    // Implement the round corners on the top.
    // Do this here because everything should have been laid out at this moment.
    //
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch (pageLabel.text) {
        case SessionPages.Welcome.rawValue:
            scrollToTopOfWelcomeView()
        case SessionPages.LogView.rawValue:
            scrollToEndOfLogView()
        default:
            return;
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setSettingSliders() {
        showBackgroundValue.isOn = Bool(sessionDelegater.getShowBackground())
        secondsBeforeCheckingLocationValue.value = Float(sessionDelegater.getSecondsBeforeCheckingLocation())
        secondsBeforeCheckingDistanceValue.value =
            Float(sessionDelegater.getSecondsBeforeCheckingDistance())
        distanceBeforeNotifyingValue.value = Float(sessionDelegater.getDistanceBeforeNotifying())
    }
    
    func getWelcomeMessage()
    {
        DispatchQueue.main.async {
            self.logView.isHidden = false
            self.logView.attributedText =  Variables.welcomeMessage.html2Attributed
            self.logView.setContentOffset(.zero, animated: false)
            self.logView.scrollRangeToVisible(NSRange(location:0, length:0))
            if #available(iOS 13.0, *) {
                self.logView.textColor = UIColor.label
            } else {
                if Variables.showBackground {
                    self.logView.textColor = UIColor.lightText
                } else {
                    self.logView.textColor = UIColor.darkText
                }
            }
        }
    }
    
    func getLogHistory()
    {
        if (pageLabel.text == SessionPages.LogView.rawValue) {
            DispatchQueue.main.async {
                self.logView.isHidden = false
                self.logView.attributedText = Variables.logHistory
                if #available(iOS 13.0, *) {
                   self.logView.textColor = UIColor.label
                } else {
                    if Variables.showBackground {
                       self.logView.textColor = UIColor.lightText
                   } else {
                       self.logView.textColor = UIColor.darkText
                   }
                }
                self.scrollToEndOfLogView()
            }
        }
    }
   
    
    // Append the message to the end of the text view and make sure it is visiable.
    //
    private func log(_ message: String) {
        let format = "#{{message}} #{{newLine}}"
        let attributedMessage = NSAttributedString(format: format,
                                         mapping: ["message": message,
                                                   "newLine": "\n"])

        if (!Variables.logHistory.mutableString.contains(message))
        {
            Variables.logHistory.append(attributedMessage)
        }
        getLogHistory()
    }
    
    func scrollToTopOfWelcomeView() {
        logView.setContentOffset(.zero, animated: true)
        logView.scrollRangeToVisible(NSRange(location:0, length:0))
    }
    
    func scrollToEndOfLogView() {
        if (pageLabel.text == SessionPages.LogView.rawValue) {
            logView.scrollRangeToVisible(NSMakeRange(0, 1))
        }
    }
    
    @IBAction func clear(_ sender: UIButton) {
        if (logView.isHidden == false) {
            if (pageLabel.text == SessionPages.LogView.rawValue) {
                Variables.logHistory = NSMutableAttributedString()
                logView.attributedText = Variables.logHistory
            }
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
        
        if (lat == testLat && long == testLong) {
            myDelegate?.requestLocation()
        } else {
            //log the messageData i.e location to the screen else show command
            if (lat != emptyDegrees && long != emptyDegrees)
            {
                if (Variables.logHistory.mutableString.contains("id")) {
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
}
