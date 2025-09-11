//
//  LoginViewModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 9.09.2025.
//

import UIKit
import Foundation
import RegexBuilder
import CryptoKit

class LoginViewModel{
    
        
    func login(email: String?, password: String?) async throws -> LoginResponse{
        // 1. TextField'ların boş olup olmadığını kontrol et
        guard let mail = email, !mail.isEmpty,
              let password = password, !password.isEmpty else {
            throw APIError.emptyFields
        }
        
        // 2. API'ye gönderilecek veri modelini oluştur
        guard Validator.isValidMail(mail) else {
            throw APIError.invalidEmail
            }
        
        // JWT işlemi için
        let passwordData = Data(password.utf8)
        let digest = SHA256.hash(data: passwordData)

        let passwordHashed = digest.map { String(format: "%02x", $0) }.joined()
        let loginData = LoginRequest(mail: mail, password: passwordHashed)
        
        

                // APIService'i çağır ve yanıtı bekle
                let response = try await APIService.shared.login(requestData: loginData)
                
                // Bu blok sadece ve sadece 200 OK durumunda çalışacak.
                print("Başarıyla giriş yapıldı: \(response.message)")
                            
                // Token'ı kaydet ve ana ekrana geç.
                KeyChainManager.shared.saveToken(token: response.token)
                //switchToMainApp()
                return response        
    }
}
