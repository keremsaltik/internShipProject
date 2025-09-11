//
//  AlertHelper.swift
//  internShipProject
//
//  Created by Kerem Saltık on 25.07.2025.
//

import Foundation

import UIKit

class AlertHelper{
    // Kullanıcıya uyarı göstermek için yardımcı fonksiyon
    static func showAlert(viewController: UIViewController ,title: String, message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Tamam", style: .default) { _ in
                // Bu kod bloğu, kullanıcı "Tamam" butonuna bastıktan sonra çalışır.
                
                // Eğer bu fonksiyona bir 'completion' bloğu gönderildiyse ('nil' değilse),
                // o bloğu burada çalıştır.
                completion?()
            }
            
            // Oluşturduğumuz bu yeni ve akıllı 'okAction'ı alert'e ekliyoruz.
            alertController.addAction(okAction)
            viewController.present(alertController, animated: true, completion: nil)

            }
    }
}
