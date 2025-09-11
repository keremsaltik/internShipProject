//
//  RegisterViewModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 11.09.2025.
//

import Foundation
import RegexBuilder
import CryptoKit

class RegisterViewModel{
    
    
    func register(name: String?,email: String?, password: String?, confirmPassword: String?) async throws -> RegisterResponse{
        guard let name = name, !name.isEmpty,
              let mail = email, !mail.isEmpty,
              let password = password, !password.isEmpty,
              let confirmPassword = confirmPassword, !confirmPassword.isEmpty else{
              throw APIError.emptyFields
            //AlertHelper.showAlert(viewController: self, title: "Hata", message: "Lütfen tüm alanları doldurun.")
        }
        
        guard Validator.isValidPassword(password) else {
           throw APIError.emptyFields
            //AlertHelper.showAlert(viewController: self, title: "Hata", message: "Şifreniz en az 8 karakter uzunluğunda olmalı ve en az bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter içermelidir.")
            
        }
        guard Validator.isPasswordMatch(password, confirmPassword) else{
            throw APIError.unauthorized(message: "Girdiğiniz şifreler eşleşmiyor")
            //AlertHelper.showAlert(viewController: self, title: "Hata", message: "Girdiğiniz şifreler eşleşmiyor")
        }
        
       
        
        // Api'ye gönderilecek veri modeli
        guard Validator.isValidMail(mail) else {
            throw APIError.invalidEmail
            //AlertHelper.showAlert(viewController: self, title: "Geçersiz E-posta", message: "Lütfen geçerli bir e-posta adresi girin.")
                
            }
        
        // Burada digest, Swift Crypto framework’ünden SHA256Digest tipinde bir nesne olur.
        // Ama SHA256Digest bir Data veya String değildir. Bu yüzden onu doğrudan MongoDB'ye (özellikle BSON/JSON üzerinden string bekleyen alanlara) kaydetmek istersen hata alırsın.
        let passwordData = Data(password.utf8)
        let digest = SHA256.hash(data: passwordData)

        // Bu satır, digest içindeki her baytı (byte) hex (onaltılık) formatta iki karakterlik bir string’e çevirir. Örneğin 0x0f byte'ı "0f" olur.
        let passwordHashed = digest.map { String(format: "%02x", $0) }.joined()

        let registerData = RegisterRequest(name: name, mail: mail, password: passwordHashed)
        
            
        let response = try await APIService.shared.register(requestData: registerData)
            
        /*if response.success {
        print("Başarıyla kayıt olundu")
        showSuccessAlertandGoBack()
        }*/
            
        return response
    }
}
