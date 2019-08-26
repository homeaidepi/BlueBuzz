import UIKit

final class FeedbackViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    var dataObject: String = ""
    
    // MARK: - Outlet
    @IBOutlet var form: Form!
    @IBOutlet weak var givenName: UITextField!
    @IBOutlet weak var familyName: UITextField!
    @IBOutlet weak var age: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var comment: UITextView!
     @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var feedbackBottomConstraint: NSLayoutConstraint!
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.givenName.delegate = self
        self.familyName.delegate = self
        self.age.delegate = self
        self.email.delegate = self
        self.comment.delegate = self
        
        setBorderColorTextField(textField: givenName, color: UIColor.yellow.cgColor)
        setBorderColorTextField(textField: familyName, color: UIColor.yellow.cgColor)
        setBorderColorTextField(textField: age, color: UIColor.yellow.cgColor)
        setBorderColorTextField(textField: email, color: UIColor.yellow.cgColor)
        setBorderColorTextView(textView: comment, color: UIColor.yellow.cgColor)
        
        updateFields()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        background.isHidden = !Variables.showBackground
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        adjustUiConstraints(size: size)
    }
    
    func adjustUiConstraints(size: CGSize) {
        var portrait = false
        
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
        } else {
            print("Portrait")
            portrait = true
        }
        
        //fix for container being offscreen
        feedbackBottomConstraint.constant = 70
        
        if (portrait) {
            //logoLeadingConstraint.constant = size.width / 2 - 50
        } else {
            //logoLeadingConstraint.constant = size.width / 2 - 50
        }
    }
    
    func setBorderColorTextField(textField:UITextField, color:CGColor ) {
        textField.layer.borderWidth = 2.0
        textField.layer.borderColor = UIColor.yellow.cgColor
        textField.layer.cornerRadius = 5;
    }
    
    func setBorderColorTextView(textView:UITextView, color:CGColor ) {
        textView.layer.borderWidth = 2.0
        textView.layer.borderColor = color
        textView.layer.cornerRadius = 5;
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
              form["email"] as Any,
              comment.text as Any)
        
        let instanceId = sessionDelegater.getInstanceIdentifier()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        let parameterDictionary = [
            "instanceId": instanceId,
            "version" : "\(appVersion)",
            "givenName": form["givenName"]! ,
            "familyName": form["familyName"]! ,
            "age": form["age"]!,
            "email": form["email"]!,
            "comment": comment.text!
            ] as [String : String]
        
        sessionDelegater.postComment(parameterDictionary: parameterDictionary, onSuccess: { (JSON) in
            
            DispatchQueue.main.async {
                self.comment.text = ""
                self.updateVariables()
                
                // create the alert
                let alert = UIAlertController(title: "Feedback Submitted", message: "Buzz worthy input. Thank you", preferredStyle: UIAlertController.Style.alert)
                
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                
                // show the alert
                self.present(alert, animated: true, completion: nil)
            }
            
        }) { (error, params) in
            //if let err = error {
                //message = "\nError: " + err.localizedDescription
            //}
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
        email.text = Variables.email
        comment.text = Variables.comment
    }
    
    func updateVariables() {
        Variables.givenName = form["givenName"] ?? ""
        Variables.familyName = form["familyName"] ?? ""
        Variables.age = form["age"] ?? ""
        Variables.email = form["email"] ?? ""
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
        updateVariables()
        return true
    }
    
    
}

