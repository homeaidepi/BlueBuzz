import UIKit

final class SplashController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlet
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var locationNotificationLabel: UILabel!
    var secondaryColor: UIColor = UIColor.white
    var primaryColor: UIColor = UIColor.black
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        background.isHidden = Variables.showBackground
        
        let showBackground = Variables.showBackground
        background.isHidden = !showBackground
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
            self.primaryColor = UIColor.label
            self.secondaryColor = UIColor.secondaryLabel
        } else {
            // Fallback on earlier versions
            if (showBackground) {
                self.view.backgroundColor = UIColor.black
                self.secondaryColor = UIColor.systemBlue
                self.primaryColor = UIColor.black
            } else {
                self.view.backgroundColor = UIColor.black
                self.secondaryColor = UIColor.systemBlue
                self.primaryColor = UIColor.white
                }
        }
        
        locationNotificationLabel.textColor = primaryColor;
        locationNotificationLabel.shadowColor = secondaryColor;
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "13.X"
        versionLabel.text = "Version \(appVersion)"
    }
}
