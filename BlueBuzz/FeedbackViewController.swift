import UIKit

final class FeedbackViewController: UIViewController {

    var dataObject: String = ""
    
    // MARK: - Outlet
    @IBOutlet var form: Form!
    
    // MARK: - Actions
    @IBAction func submit() {
        print("Form Data:",
              form["firstName"] as Any,
              form["lastName"] as Any,
              form["age"] as Any)
    }
}

