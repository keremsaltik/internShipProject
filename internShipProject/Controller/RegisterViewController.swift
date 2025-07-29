//
//  RegisterViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 24.07.2025.
//

import UIKit
import RegexBuilder
import CryptoKit
import Foundation

class RegisterViewController: UIViewController {

    //MARK: - Variables
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var mailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    

    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //MARK: - Actions
    @IBAction func registerButtonTapped(_ sender: UIButton){
        guard let name = nameField.text, !name.isEmpty,
              let mail = mailField.text, !mail.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordField.text, !confirmPassword.isEmpty else{
            AlertHelper.showAlert(viewController: self, title: "Hata", message: "Lütfen tüm alanları doldurun.")
                return
        }
        
        guard Validator.isValidPassword(password) else {
            AlertHelper.showAlert(viewController: self, title: "Hata", message: "Şifreniz en az 8 karakter uzunluğunda olmalı ve en az bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter içermelidir.")
            return
        }
        guard Validator.isPasswordMatch(password, confirmPassword) else{
            AlertHelper.showAlert(viewController: self, title: "Hata", message: "Girdiğiniz şifreler eşleşmiyor")
            return
        }
        
       
        
        // Api'ye gönderilecek veri modeli
        guard Validator.isValidMail(mail) else {
            AlertHelper.showAlert(viewController: self, title: "Geçersiz E-posta", message: "Lütfen geçerli bir e-posta adresi girin.")
                return
            }
        
        // Burada digest, Swift Crypto framework’ünden SHA256Digest tipinde bir nesne olur.
        // Ama SHA256Digest bir Data veya String değildir. Bu yüzden onu doğrudan MongoDB'ye (özellikle BSON/JSON üzerinden string bekleyen alanlara) kaydetmek istersen hata alırsın.
        let passwordData = Data(password.utf8)
        let digest = SHA256.hash(data: passwordData)

        // Bu satır, digest içindeki her baytı (byte) hex (onaltılık) formatta iki karakterlik bir string’e çevirir. Örneğin 0x0f byte'ı "0f" olur.
        let passwordHashed = digest.map { String(format: "%02x", $0) }.joined()

        let registerData = RegisterRequest(name: name, mail: mail, password: passwordHashed)
        
        Task{
            do{
                let response = try await APIService.shared.register(requestData: registerData)
                
                if response.success{
                    print("Başarıyla kayıt olundu")
                    showSuccessAlertandGoBack()
                }else{
                    print("Kayıt hatası: \(response.message)")
                    AlertHelper.showAlert(viewController: self, title: "Ağ hatası", message: "Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyiniz.")
                }
            }
        }
    }

  
    //MARK: - Functions
    
    func showSuccessAlertandGoBack() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Başarılı", message: "Kaydınız başarıyla oluşturuldu. Giriş Sayfasına Yönlendiriliyorsunuz.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            
            self.present(alert, animated: true)
        }
    }
}
