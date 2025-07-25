//
//  UserModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 23.07.2025.
//

import Foundation

struct LoginRequest:Codable{
    let mail: String
    let password: String
}

struct LoginResponse: Codable{
    let success: Bool
    let message: String
}

struct RegisterRequest: Codable{
    let name: String
    let mail: String
    let password: String
    
}

struct RegisterResponse: Codable{
    let success: Bool
    let message: String
}
