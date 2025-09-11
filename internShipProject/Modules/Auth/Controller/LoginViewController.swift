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
    @IBOutlet weak var loginButton: UIButton!
    
    private var loginViewModel = LoginViewModel()
    
    
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    //MARK: - Actions
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        
        Task{
            do{
                _ = try await loginViewModel.login(email: emailTextField.text, password: passwordTextField.text)
                
                DispatchQueue.main.async {
                    self.switchToMainApp()
                }
            }catch {
                let message: String
                if let apiError = error as? APIError {
                    message = apiError.errorDescription ?? "Bilinmeyen hata"
                } else {
                    message = error.localizedDescription
                }
                DispatchQueue.main.async {
                    AlertHelper.showAlert(viewController: self, title: "Hata", message: message)
                }
            }
        }
    }
    
    
    //MARK: - Functions
    // Ana uygulama arayüzüne geçişi yöneten fonksiyon
    func switchToMainApp() {
        DispatchQueue.main.async {
            guard let mainNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "toHomePageTabBarController") else {
                print("Hata: toHomePageTabBarController storyboard'da bulunamadı.")
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
