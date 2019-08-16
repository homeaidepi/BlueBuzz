//
//  Validator.swift
//  FormsExample
//
//  Created by Downey, Eric on 8/24/18.
//  Copyright © 2018 downey. All rights reserved.
//

import Foundation

@objc protocol Validator {
    func validate(_ text: String?) -> Bool
}
