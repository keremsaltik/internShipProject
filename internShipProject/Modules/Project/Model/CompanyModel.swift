//
//  CompanyModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 8.08.2025.
//

import Foundation

struct CompanyModel: Codable{
    let id: String
    let companyName: String
    let foundationYear: String
    let headquarters: String
    let website: String
    let categories: [String]
    
    
    enum CodingKeys: String, CodingKey{
        case id = "_id"
        case companyName
        case foundationYear
        case headquarters
        case website
        case categories
    }
}
