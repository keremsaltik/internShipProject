//
//  ProjectModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 30.07.2025.
//

import Foundation

struct ProjectModel: Codable, Identifiable{
    let id: String
    let mail: String
    var title: String
    var description:String
    var startDate: Date
    var endDate: Date
    var status: String
    var category: String?
    var priority: String?
    var projectManager: String?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id" // <-- "Eğer JSON'da '_id' diye bir şey görürsen, onu benim 'id' özelliğime ata"
        case mail, title, description, startDate, endDate, status, category, priority, projectManager, createdAt, updatedAt
    }
    
    
}
