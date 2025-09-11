//
//  CategoryModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 6.08.2025.
//

import Foundation

struct CategoryModel: Codable, Identifiable{
    let id: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
            case id = "_id"
            case name
        }
}
