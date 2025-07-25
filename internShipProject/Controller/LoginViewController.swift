//  LoginViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 23.07.2025.
//

import UIKit
import RegexBuilder
import CryptoKit

class LoginViewController: UIViewController {
    
    //MARK: - Variables
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rememberMeSwitch: UISwitch!
    @IBOutlet weak var loginButton: UIButton!
    
    let userOptions = UserDefaults.standard
    
    
    
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let mail = userOptions.string(forKey: "mail"),
              let password = userOptions.string(forKey: "password") else {
            return
        }

        Task {
            let rememberedData = LoginRequest(mail: mail, password: password)
            do {
                let rememberedResponse = try await APIService.shared.login(requestData: rememberedData)
                if rememberedResponse.success {
                    switchToMainApp()
                } else {
                    print("Bağlantı hatası")
                }
            } catch {
                print("Otomatik giriş sırasında hata: \(error)")
            }
        }
    }

    //MARK: - Actions
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        
        // 1. TextField'ların boş olup olmadığını kontrol et
        guard let mail = emailTextField.text, !mail.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            AlertHelper.showAlert(viewController: self, title: "Hata", message: "Lütfen tüm alanları doldurun.")
            return
        }
        
        // 2. API'ye gönderilecek veri modelini oluştur
        guard Validator.isValidMail(mail) else {
            AlertHelper.showAlert(viewController: self, title: "Geçersiz E-posta", message: "Lütfen geçerli bir e-posta adresi girin")
                return
            }
        
        let passwordData = Data(password.utf8)
        let digest = SHA256.hash(data: passwordData)

        let passwordHashed = digest.map { String(format: "%02x", $0) }.joined()
        let loginData = LoginRequest(mail: mail, password: passwordHashed)
        
        Task {
            do {
                // APIService'i çağır ve yanıtı bekle
                let response = try await APIService.shared.login(requestData: loginData)
                
                if response.success {
                    // GİRİŞ BAŞARILI
                    print("Başarıyla giriş yapıldı: \(response.message)")
                    if rememberMeSwitch.isOn {
                        userOptions.set(mail, forKey: "mail")
                        userOptions.set(passwordHashed, forKey: "password")
                    }
                    switchToMainApp()
                } else {
                    // GİRİŞ BAŞARISIZ
                    print("Giriş hatası: \(response.message)")
                    AlertHelper.showAlert(viewController: self, title: "Giriş Başarısız", message: response.message)
                }
                
            } catch {
                // AĞ HATASI
                print("API isteğinde bir hata oluştu: \(error.localizedDescription)")
                AlertHelper.showAlert(viewController: self, title: "Ağ hatası", message: "Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.")
            }
        }
        
    }
    
    
    //MARK: - Functions
    // Ana uygulama arayüzüne geçişi yöneten fonksiyon
    func switchToMainApp() {
        DispatchQueue.main.async {
            guard let mainNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "toHomePageNavigationController") else {
                print("Hata: toHomePageNavigationController storyboard'da bulunamadı.")
                return
            }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate,
               let window = sceneDelegate.window {
                
                window.rootViewController = mainNavigationController
                UIView.transition(with: window,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: nil,
                                  completion: nil)
            }
        }
    }
    
 
}
