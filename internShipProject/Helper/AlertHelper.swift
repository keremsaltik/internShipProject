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
    static func showAlert(viewController: UIViewController ,title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Tamam", style: .default))
            viewController.present(alertController, animated: true)
        }
    }
}
