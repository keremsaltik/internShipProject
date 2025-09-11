//
//  ProjectDetailViewModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 11.09.2025.
//

import Foundation

@MainActor
class ProjectDetailViewModel {
    
    // MARK: - Properties
        
        private(set) var detailItems: [ProjectDetailModel] = []
        private(set) var project: ProjectModel
        
        var projectTitle: String {
            return project.title
        }
        
        // MARK: - Initializer
        
        init(project: ProjectModel) {
            self.project = project
            prepareDisplayData()
        }
        
        // MARK: - Public Functions
        
        func getShareURL() -> URL? {
            guard let projectTitle = project.title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                return nil
            }
            let shareUrlString = "\(NetworkInfo.Hosts.localHost)/share/\(projectTitle)"
            return URL(string: shareUrlString)
        }
        
        /// ViewModel'i yeni proje verisiyle günceller ve gösterilecek listeyi yeniden oluşturur.
        func update(with newProject: ProjectModel) {
            self.project = newProject
            prepareDisplayData()
        }
        
        // MARK: - Private Helper Functions
        
        private func prepareDisplayData() {
            detailItems.removeAll()
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.locale = Locale(identifier: "tr_TR")
            
            let startDate = dateFormatter.string(from: project.startDate)
            let endDate = dateFormatter.string(from: project.endDate)
            
            detailItems.append(ProjectDetailModel(label: "Açıklama", value: project.description, iconName: "text.alignleft"))
            detailItems.append(ProjectDetailModel(label: "Durum", value: project.status, iconName: "hourglass"))
            detailItems.append(ProjectDetailModel(label: "Başlangıç Tarihi", value: startDate, iconName: "calendar.badge.plus"))
            detailItems.append(ProjectDetailModel(label: "Bitiş Tarihi", value: endDate, iconName: "calendar.badge.minus"))
            detailItems.append(ProjectDetailModel(label: "İlgili E-posta", value: project.mail, iconName: "envelope.fill"))
            detailItems.append(ProjectDetailModel(label: "Proje Kategorisi", value: project.category ?? "", iconName: "tag.fill"))
            detailItems.append(ProjectDetailModel(label: "Proje Önem Derecesi", value: project.priority ?? "", iconName:"exclamationmark.circle.fill"))
            detailItems.append(ProjectDetailModel(label: "Proje Yetkilisi", value: project.projectManager ?? "", iconName: "person"))
            
            if !project.employees.isEmpty {
                let memberNames = project.employees.map { $0.name }.joined(separator: ", ")
                detailItems.append(ProjectDetailModel(label: "Proje Üyeleri", value: memberNames, iconName: "person.3.fill"))
            }
            detailItems.append(ProjectDetailModel(label: "Proje Sahibi Şirket", value: project.company ?? "", iconName: "building.fill"))
        }
}
