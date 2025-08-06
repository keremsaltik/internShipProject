//
//  CreateProjectModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 1.08.2025.
//

import Foundation
// Proje oluşturmak için model.
struct CreateProjectRequest: Codable{
    let title: String
    let description: String
    let startDate: String
    let endDate: String
    let status: String
    let category: String
    let priority: String
    let projectManager: String
}

// Backend üzerinden gelecek yanıt için.
struct ProjectResponse: Codable{
    let success: Bool
    let message: String?
}
