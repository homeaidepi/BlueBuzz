//
//  TextField.swift
//  FormsExample
//
//  Created by Downey, Eric on 8/20/18.
//  Copyright © 2018 downey. All rights reserved.
//

import UIKit

@IBDesignable class TextField: UITextField {
    
    // MARK: - Inspectables
    
    @IBInspectable var key: String?
    
    // MARK: - Outlets
    
    @IBOutlet var validators: [Validator]?
}

extension TextField: FormControl {
    var isValid: Bool {
        return validators?.reduce(true) { result, next in
            result && next.validate(text)
        } ?? true
    }
    
    func clear() {
        text = nil
    }
}
