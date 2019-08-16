//
//  EmailValidator.swift
//  FormsExample
//
//  Created by Downey, Eric on 8/24/18.
//  Copyright © 2018 downey. All rights reserved.
//

import Foundation

final class EmailValidator: NSObject, Validator {
    
    // MARK: - Properties
    
    private var emailRegexStr = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
    
    // MARK: - Methods
    
    func validate(_ text: String?) -> Bool {
        guard let text = text else {
            return false
        }
        do {
            let expression = try NSRegularExpression(pattern: emailRegexStr,
                                                     options: .caseInsensitive)
            let matches = expression.matches(in: text,
                                             options: [],
                                             range: NSRange(text.startIndex..<text.endIndex, in: text))
            return matches.count > 0
        }
        catch {}
        return false
    }
}
