//
//  FormControl.swift
//  FormsExample
//
//  Created by Downey, Eric on 8/20/18.
//  Copyright © 2018 downey. All rights reserved.
//

import Foundation

@objc protocol FormControl {
    var key: String? { get }
    var text: String? { get }
    var validators: [Validator]? { get }
    var isValid: Bool { get }
    
    func clear()
}
