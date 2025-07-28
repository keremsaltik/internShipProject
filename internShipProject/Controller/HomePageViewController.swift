//
//  HomePageViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 25.07.2025.
//

import UIKit

class HomePageViewController: UIViewController {
    
    //MARK: - Variables
    @IBOutlet weak var logOutButton: UIBarButtonItem!
    let userOptions = UserDefaults.standard

    
    //MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: - Actions
    @IBAction func logOutButtonTapped(_ sender: UIButton){
        userOptions.removeObject(forKey: "mail")
        userOptions.removeObject(forKey: "password")
     
        verifyandSwitch()
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
    
    func verifyandSwitch(){
        if userOptions.string(forKey: "mail") == nil && userOptions.string(forKey: "password") == nil{
            print("Veriler silindi ana sayfaya geçiş yapılıyor...")
            switchToMainApp()
        }else{
            print("Veriler mevcut, siliniyor...")
            userOptions.removeObject(forKey: "mail")
            userOptions.removeObject(forKey: "password")
            verifyandSwitch()
        }
    }
}
