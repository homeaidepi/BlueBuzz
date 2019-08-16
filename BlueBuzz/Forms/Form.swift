//
//  Form.swift
//  FormsExample
//
//  Created by Downey, Eric on 8/20/18.
//  Copyright © 2018 downey. All rights reserved.
//

import Foundation

class Form: NSObject {
    
    // MARK: - Outlets
    
    @IBOutlet var controls: [FormControl]?
    
    // MARK: - Properties
    
    var isValid: Bool {
        return controls?.reduce(true) { result, next in
            result && next.isValid
        } ?? true
    }
    
    // MARK: - Subscripts
    
    subscript(_ key: String) -> String? {
        return value(for: key)
    }
    
    // MARK: - Methods
    
    func value(for key: String) -> String? {
        return controls?.first(where: { $0.key == key })?.text
    }
    
    func clear() {
        controls?.forEach { $0.clear() }
    }
}
