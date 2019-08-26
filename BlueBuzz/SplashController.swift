import UIKit

final class SplashController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlet
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var versionLabel: UILabel!
       
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        background.isHidden = Variables.showBackground
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "13.X"
        versionLabel.text = "Version \(appVersion)"
    }
}

