//
//  ProfileViewModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 11.09.2025.
//

import Foundation

class ProfileViewModel{
    func logOut(){
        KeyChainManager.shared.deleteToken()
    }
    
    func loadUserProfile(completion: @escaping (Result<ProfileResponse, Error>) -> Void){
        // Yazılan profili alma fonksiyonu.
        APIService.shared.fetchProfile{ result in
            DispatchQueue.main.async{
                completion(result)
            }
        }
    }
}
