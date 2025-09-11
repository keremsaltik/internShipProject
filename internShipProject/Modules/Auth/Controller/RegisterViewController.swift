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
    
    private let registerViewModel = RegisterViewModel()

    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //MARK: - Actions
    @IBAction func registerButtonTapped(_ sender: UIButton){
        Task{
            do{
               _ = try await registerViewModel.register(name: nameField.text, email: mailField.text, password: passwordField.text, confirmPassword: confirmPasswordField.text)
                
                DispatchQueue.main.async {
                    self.showSuccessAlertandGoBack()
                }
            }catch{
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
