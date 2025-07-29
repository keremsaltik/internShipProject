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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loadUserProfile()
    }
    
    //MARK: - Actions
    @IBAction func logOutButtonTapped(_ sender: UIButton){
       
     
        KeyChainManager.shared.deleteToken()
        
        switchToMainApp()
    }
    
    //MARK: - Functions
    
    func fetchProfile(completion: @escaping (Result<ProfileResponse, Error>) -> Void){
        // Önce token'ı alalım.
        guard let token = KeyChainManager.shared.getToken() else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token not found. Please login."])))
            return }
        
        guard let url = URL(string: "\(NetworkInfo.Hosts.localHost)/profile") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 2. En önemli kısım: Authorization başlığını ekle
        // Format: "Bearer <token>"
        request.setValue("Bearer \(token) ", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) {data, response, error in
            if let error = error{
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                // Token geçersiz veya süresi dolmuş. Kullanıcıyı tekrar login ekranına yönlendir.
                completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])))
                           return
            }
            
            guard let data = data else { return }
            
            do {
                let profile = try JSONDecoder().decode(ProfileResponse.self, from: data)
                completion(.success(profile))
            }catch{
                completion(.failure(error))
            }
        }.resume()
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
    
    
    func loadUserProfile(){
        // Yazılan profili alma fonksiyonu.
        fetchProfile{
            [weak self] result in
            DispatchQueue.main.async{
                switch(result){
                case .success(let profileResponse):
                    // Başarılı: Gelen taze verilerle label'ları güncelle
                    self?.nameLabel.text = profileResponse.name
                    self?.mailLabel.text = profileResponse.mail
                
                case .failure(let error):
                    AlertHelper.showAlert(viewController: self!, title: "Hata", message: "Profil bilgileri alınamadı.")
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
    
}
