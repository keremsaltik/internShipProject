//
//  SceneDelegate.swift
//  internShipProject
//
//  Created by Kerem Saltık on 23.07.2025.
//

import UIKit
import JWTDecode

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                // Keychain'den token'ı kontrol et
                if let token = KeyChainManager.shared.getToken() {
                    // TOKEN VAR: Şimdi geçerliliğini kontrol et.
                    do {
                        let jwt = try decode(jwt: token)
                        
                        // Token'ın süresi dolmuş mu?
                        if jwt.expired {
                            // SÜRESİ DOLMUŞ: Kullanıcıyı giriş ekranına yönlendir ve eski token'ı sil.
                            print("Token bulundu ama süresi dolmuş. Giriş ekranına yönlendiriliyor...")
                            KeyChainManager.shared.deleteToken() // Önemli: Süresi dolmuş token'ı temizle!
                            
                            let loginViewController = storyboard.instantiateViewController(withIdentifier: "toLoginPageNavigationController")
                            window.rootViewController = loginViewController
                        } else {
                            // GEÇERLİ TOKEN: Kullanıcıyı ana ekrana yönlendir.
                            print("Token geçerli. Anasayfaya yönlendiriliyor...")
                            let mainViewController = storyboard.instantiateViewController(withIdentifier: "toHomePageTabBarController")
                            window.rootViewController = mainViewController
                        }
                    } catch {
                        // DECODE HATASI: Token bozuk veya geçersiz. Giriş ekranına yönlendir.
                        print("Token decode edilemedi (bozuk token). Giriş ekranına yönlendiriliyor...")
                        KeyChainManager.shared.deleteToken() // Bozuk token'ı da temizle.

                        let loginViewController = storyboard.instantiateViewController(withIdentifier: "toLoginPageNavigationController")
                        window.rootViewController = loginViewController
                    }
                } else {
                    // TOKEN YOK: Kullanıcı giriş yapmamış. Giriş ekranına yönlendir.
                    print("Token bulunamadı. Giriş ekranına yönlendiriliyor...")
                    let loginViewController = storyboard.instantiateViewController(withIdentifier: "toLoginPageNavigationController")
                    window.rootViewController = loginViewController
                }
                
                self.window = window
                window.makeKeyAndVisible()    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

