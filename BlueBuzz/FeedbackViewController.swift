import UIKit

final class FeedbackViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    var dataObject: String = ""
    
    // MARK: - Outlet
    @IBOutlet var form: Form!
    @IBOutlet weak var givenName: UITextField!
    @IBOutlet weak var familyName: UITextField!
    @IBOutlet weak var age: UITextField!
    @IBOutlet weak var comment: UITextView!
    
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

