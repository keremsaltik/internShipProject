//
//  KeyChainManager.swift
//  internShipProject
//
//  Created by Kerem Saltık on 28.07.2025.
//

import Foundation
import KeychainAccess


struct KeyChainManager{
    static let shared = KeyChainManager()
    private let keyChain = Keychain(service: "com.internShipProject.app")
    
    private init() {}
    
    // Token'ı kaydetme
    func saveToken(token: String){
        keyChain["userToken"] = token
    }

    // Token'ı okuma
    func getToken() -> String? {
        return keyChain["userToken"]
    }

    // Token'ı silme (Çıkış yaparken)
    func deleteToken(){
        keyChain["userToken"] = nil
    }

}


