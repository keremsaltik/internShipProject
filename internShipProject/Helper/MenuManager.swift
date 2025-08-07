//
//  MenuManager.swift
//  internShipProject
//
//  Created by Kerem Saltık on 6.08.2025.
//

import Foundation
import UIKit

struct MenuManager{
    // --- Proje Yöneticisi Menüsünü Ayarlama ---
    func fetchManagersandSetupMenu(button: UIButton, onSelect: @escaping (UserViewModel?) -> Void) async{
        do{
            let users = try await APIService.shared.fetchAllUsers()
            DispatchQueue.main.async{
                let menuClosure = { (action: UIAction)  in
                    let selected = users.first(where: { $0.name == action.title })
                    button.setTitle(selected?.name ?? "Yönetici Seçin", for: .normal)
                    onSelect(selected)
                }
                
                let menuItems = users.map { user in
                                    UIAction(title: user.name, handler: menuClosure)
                                }

                                button.menu = UIMenu(children: menuItems)
                                button.showsMenuAsPrimaryAction = true
                                button.setTitle("Yönetici Seçin", for: .normal)
            }
        
        
    }catch {
                    print("Kullanıcı listesi çekilemedi: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        button.setTitle("Yönetici Yok", for: .normal)
                        onSelect(nil)
                    }
                }
        
    }
    
    
    func fetchCategoriesandSetupMenu(button: UIButton, onSelect: @escaping (CategoryModel?) ->  Void) async {
        do{
            let categories = try await APIService.shared.fetchCategories()
            DispatchQueue.main.async{
                let menuClosure = { (action: UIAction) in
                
                    let selected = categories.first(where: {$0.name == action.title})
                    button.setTitle(selected?.name ?? "Kategori Seçin", for: .normal)
                    onSelect(selected)
                    
                }
            }
        }catch{
            print("Kategori litesi çekilemedi \(error.localizedDescription)")
            DispatchQueue.main.async{
                button.setTitle("Yönetici Yok", for: .normal)
                onSelect(nil)
            }
        }
    }
}
