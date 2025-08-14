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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loadUserProfile()
    }
    
    //MARK: - Actions
    @IBAction func logOutButtonTapped(_ sender: UIButton){
        // Kaydedilen JSON Web Token'i silmeyi sağlar.
        KeyChainManager.shared.deleteToken()
        
        switchToMainApp()
    }
    
    //MARK: - Functions
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
    
    
    func loadUserProfile(){
        // Yazılan profili alma fonksiyonu.
        APIService.shared.fetchProfile{
            [weak self] result in
            DispatchQueue.main.async{
                switch(result){
                case .success(let profileResponse):
                    // Başarılı: Gelen taze verilerle label'ları güncelle
                    self?.nameLabel.text = profileResponse.name
                    self?.mailLabel.text = profileResponse.mail
                    self?.companyLabel.text = profileResponse.company
                
                case .failure(let error):
                    AlertHelper.showAlert(viewController: self!, title: "Hata", message: "Profil bilgileri alınamadı.", completion: {
                        // Bu kod bloğu, kullanıcı "Tamam" butonuna bastıktan
                        // sonra çalışacaktır.
                        print("Alert'in Tamam butonuna basıldı. Giriş ekranına yönlendiriliyor...")
                        self?.logOutAndGoToLogin()})
                    // Başarısız: Hata mesajı göster
                    print("Profil bilgileri alınamadı: \(error.localizedDescription)")
                    // --- BU SATIRLARI EKLE ---
                        print("----- HATA DETAYI -----")
                        print("Hatanın kendisi: \(error)")
                        print("Hatanın açıklaması: \(error.localizedDescription)")
                        }
                        print("-----------------------")
                }
            
            }
        }
    
    func logOutAndGoToLogin(){
        KeyChainManager.shared.deleteToken()
                switchToMainApp()
    }
    
}
