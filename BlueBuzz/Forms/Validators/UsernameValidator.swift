//
//  UsernameValidator.swift
//  FormsExample
//
//  Created by Downey, Eric on 8/24/18.
//  Copyright © 2018 downey. All rights reserved.
//

import Foundation

final class UsernameValidator: NSObject, Validator {
    func validate(_ text: String?) -> Bool {
        guard let text = text else {
            return false
        }
        return text.count >= 8
    }
}
