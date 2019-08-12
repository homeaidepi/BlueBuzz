import UIKit

final class FeedbackViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    var dataObject: String = ""
    
    // MARK: - Outlet
    @IBOutlet var form: Form!
    @IBOutlet weak var givenName: UITextField!
    @IBOutlet weak var familyName: UITextField!
    @IBOutlet weak var age: UITextField!
    @IBOutlet weak var comment: UITextView!
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.givenName.delegate = self
        self.familyName.delegate = self
        self.age.delegate = self
        self.comment.delegate = self
        
        updateFields()
    }
    
    @IBAction func textFieldDidEndEditing(_ textField: UITextField) {
        updateVariables()
    }
    
    // MARK: - Actions
    @IBAction func submit() {
        print("Form Data:",
              form["givenName"] as Any,
              form["familyName"] as Any,
              form["age"] as Any,
              comment.text as Any)
        
        let instanceId = sessionDelegater.getInstanceIdentifier()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        let parameterDictionary = [
            "instanceId": instanceId,
            "version" : "\(appVersion)",
            "givenName": form["givenName"]! ,
            "familyName": form["familyName"]! ,
            "age": form["age"]!,
            "comment": comment.text!
            ] as [String : String]
        
        sessionDelegater.postComment(parameterDictionary: parameterDictionary, onSuccess: { (JSON) in
            
            DispatchQueue.main.async {
                self.givenName.text = ""
                self.familyName.text = ""
                self.age.text = ""
                self.comment.text = ""
                
                // create the alert
                let alert = UIAlertController(title: "Feedback Submitted", message: "Buzz worthy input. Thank you", preferredStyle: UIAlertController.Style.alert)
                
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                
                // show the alert
                self.present(alert, animated: true, completion: nil)
            }
            
        }) { (error, params) in
            if let err = error {
                //message = "\nError: " + err.localizedDescription
            }
            //message += "\nParameters passed are: " + String(describing:params)
            
//            DispatchQueue.main.async {
//                self.logView.attributedText = message.html2Attributed
//                self.logView.textColor = UIColor(white: 1, alpha: 1)
//            }
        }
        
    }
    
    func updateFields() {
        givenName.text = Variables.givenName
        familyName.text = Variables.familyName
        age.text = Variables.age
        comment.text = Variables.comment
    }
    
    func updateVariables() {
        Variables.givenName = form["givenName"] ?? ""
        Variables.familyName = form["familyName"] ?? ""
        Variables.age = form["age"] ?? ""
        Variables.comment = comment.text ?? ""
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        updateVariables()
        
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        comment.resignFirstResponder()
        return true
    }
    
    
}

