//
//  Validator.swift
//  internShipProject
//
//  Created by Kerem Saltık on 25.07.2025.
//

import Foundation
import RegexBuilder

struct Validator{
    private static let mailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
    private static let passwordPattern = #"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*\-]).{8,}$"#
    
    static func isValidMail(_ mail: String) -> Bool{
        return (try? Regex(mailPattern).wholeMatch(in: mail)) != nil
    }
    
    static func isValidPassword(_ password: String) -> Bool{
        return (try? Regex(passwordPattern).wholeMatch(in: password)) != nil
    }
    
    static func isPasswordMatch(_ password: String, _ confirmPassword: String) -> Bool{
        return password == confirmPassword
    }
}
