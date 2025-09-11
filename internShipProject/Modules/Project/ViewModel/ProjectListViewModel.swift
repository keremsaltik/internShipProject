//
//  ProjectListViewModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 11.09.2025.
//

import Foundation

@MainActor
class ProjectListViewModel {
    
    // MARK: - Properties
    
    // API'den gelen tüm projelerin ham listesi. Sadece bu sınıf değiştirebilir.
    private var allProjects: [ProjectModel] = []
    
    // ViewController'ın göstereceği, filtrelenmiş ve sıralanmış liste.
    // Dışarıdan sadece okunabilir.
    private(set) var visibleProjects: [ProjectModel] = []
    
    private var currentSearchText: String = ""
    
    // MARK: - API Calls
    
    /// Sunucudan tüm projeleri çeker ve listeyi günceller.
    func fetchProjects() async throws {
        let projects = try await APIService.shared.fetchProjects()
        self.allProjects = projects
        // Veri geldikten sonra mevcut filtreyi uygula.
        applyFilter()
    }
    
    /// Belirtilen index'teki projeyi siler.
    func deleteProject(at indexPath: IndexPath) async throws {
        // Silinecek projeyi 'görünür' listeden bul.
        let projectToDelete = visibleProjects[indexPath.row]
        
        // API isteğini yap (senin kodundaki gibi proje başlığı ile).
        _ = try await APIService.shared.deleteProject(projectTitle: projectToDelete.title)
        
        // API isteği başarılı olursa, projeyi ana listeden kaldır.
        allProjects.removeAll { $0.id == projectToDelete.id }
        
        // Filtreyi yeniden uygulayarak görünür listeyi de güncelle.
        applyFilter()
    }
    
    // MARK: - Data Manipulation
    
    /// Proje listesini belirtilen metne göre filtreler.
    func filter(with searchText: String) {
        self.currentSearchText = searchText.lowercased()
        applyFilter()
    }
    
    // MARK - Private Helper
    
    /// Arama mantığını merkezi olarak yöneten fonksiyon.
    private func applyFilter() {
        if currentSearchText.isEmpty {
            // Arama metni yoksa, tüm projeleri göster.
            visibleProjects = allProjects
        } else {
            // Arama metni varsa, başlığa göre filtrele.
            visibleProjects = allProjects.filter { project in
                project.title.lowercased().contains(currentSearchText)
            }
        }
    }
}
