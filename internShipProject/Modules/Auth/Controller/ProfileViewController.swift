//
//  ProfileViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 28.07.2025.
//

import UIKit

class ProfileViewController: UIViewController {

    //MARK: - Variables
    @IBOutlet weak var logOutButton: UIBarButtonItem!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    
    private let profileViewModel = ProfileViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        fetchProfileData()
    }
    
    //MARK: - Actions
    @IBAction func logOutButtonTapped(_ sender: UIButton){
        // Kaydedilen JSON Web Token'i silmeyi sağlar.
        profileViewModel.logOut()
        switchToMainApp()
    }
    
    //MARK: - Functions
    private func fetchProfileData() {
        profileViewModel.loadUserProfile { [weak self] result in
                // self'in hala var olduğundan emin olalım.
                guard let self = self else { return }
                
                switch result {
                case .success(let profileResponse):
                    // Başarılı: Gelen verilerle label'ları güncelle
                    self.updateUI(with: profileResponse)
                
                case .failure(let error):
                    // Başarısız: Hata detayını logla ve kullanıcıya uyarı göster
                    print("Profil bilgileri alınamadı: \(error.localizedDescription)")
                    self.showProfileErrorAlert()
                }
            }
        }
    
    /// Gelen profil verileriyle UI elemanlarını günceller.
        private func updateUI(with profile: ProfileResponse) {
            self.nameLabel.text = profile.name
            self.mailLabel.text = profile.mail
            self.companyLabel.text = profile.company
        }
    
    private func showProfileErrorAlert() {
           let alert = UIAlertController(title: "Hata", message: "Profil bilgileri alınamadı. Lütfen tekrar giriş yapın.", preferredStyle: .alert)
           
           let okAction = UIAlertAction(title: "Tamam", style: .default) { _ in
               // Kullanıcı "Tamam" butonuna basınca çıkış yap ve giriş ekranına yönlendir.
               self.logOutAndGoToLogin()
           }
           
           alert.addAction(okAction)
           self.present(alert, animated: true)
       }
       
    
    func logOutAndGoToLogin(){
        profileViewModel.logOut()
        switchToMainApp()
    }
    
    func switchToMainApp() {
        DispatchQueue.main.async {
            guard let mainNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "toLoginPageNavigationController") else {
                print("Hata: toLoginPageNavigationController storyboard'da bulunamadı.")
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
