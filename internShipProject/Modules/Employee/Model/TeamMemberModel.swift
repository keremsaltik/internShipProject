//
//  EmployeeModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 12.08.2025.
//

import Foundation
 
struct EmployeeModel: Codable{
    let userId: String?
    let name: String
    let mail: String
    
    enum CodingKeys: String, CodingKey {
            case userId = "_id"
            case name
            case mail
        }
}
