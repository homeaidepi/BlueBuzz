import UIKit

final class SplashController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlet
    @IBOutlet weak var background: UIImageView!
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        background.isHidden = Variables.hideBackground
        
    }
}

