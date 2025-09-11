//
//  EditProjectViewModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 11.09.2025.
//

import Foundation

@MainActor
class EditProjectViewModel {
    
    // MARK: - Custom Errors for Validation
    enum ValidationError: LocalizedError {
        case missingProjectManager
        case missingCategory
        case missingCompany
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .missingProjectManager: return "Lütfen bir proje yöneticisi seçin."
            case .missingCategory: return "Lütfen bir kategori seçin."
            case .missingCompany: return "Lütfen bir şirket seçin."
            case .apiError(let message): return message
            }
        }
    }
    
    // MARK: - Properties
    
    private let projectId: String
    
    // Formdaki güncel verileri tutan değişkenler
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var status: String
    var priority: String
    var companyName: String
    
    var selectedCategory: String?
    var selectedProjectManager: UserInfoModel?
    var selectedCompany: CompanyModel?
    var selectedEmployees: [UserInfoModel] = []
    
    // Menüler için veri kaynakları
    private(set) var availableManagers: [UserInfoModel] = []
    private(set) var availableCompanies: [CompanyModel] = []
    
    // MARK: - Initializer
    
    init(project: ProjectModel) {
        self.projectId = project.id
        self.title = project.title
        self.description = project.description
        self.startDate = project.startDate
        self.endDate = project.endDate
        self.status = project.status
        self.priority = project.priority ?? "Normal"
        self.companyName = project.company ?? ""
        self.selectedCategory = project.category
        
        self.selectedEmployees = project.employees.map { UserInfoModel(name: $0.name, mail: $0.mail) }
        self.selectedProjectManager = UserInfoModel(name: project.projectManager ?? "", mail: "")
    }
    
    // MARK: - API Calls
    
    func fetchInitialData() async throws {
        async let companiesTask = APIService.shared.fetchAllCompanies()
        async let usersTask = APIService.shared.fetchAllUsers()
        
        let (companies, users) = try await (companiesTask, usersTask)
        
        self.availableCompanies = companies
        self.availableManagers = users
        
        updateInitialSelections(with: users)
    }
    
    /// Projeyi günceller ve güncellenmiş ProjectModel'i geri döndürür.
    func updateProject() async throws -> ProjectModel {
        try validateInputs()
        
        let updatedProject = ProjectModel(
            id: self.projectId,
            mail: selectedProjectManager!.mail,
            title: self.title,
            description: self.description,
            startDate: self.startDate,
            endDate: self.endDate,
            status: self.status,
            category: selectedCategory!,
            priority: self.priority,
            projectManager: selectedProjectManager!.name,
            employees: self.selectedEmployees.map { EmployeeModel(userId: "", name: $0.name, mail: $0.mail) },
            company: selectedCompany!.companyName
        )
        
        let response = try await APIService.shared.updateProject(projectData: updatedProject)
        
        if !response.success {
            throw ValidationError.apiError(response.message ?? "Proje güncellenemedi.")
        }
        
        // Başarılı olursa, güncellenmiş modeli geri döndür.
        return updatedProject
    }
    
    // MARK: - Private Helpers
    
    private func validateInputs() throws {
        guard selectedProjectManager != nil else { throw ValidationError.missingProjectManager }
        guard selectedCategory != nil else { throw ValidationError.missingCategory }
        guard selectedCompany != nil else { throw ValidationError.missingCompany }
    }
    
    private func updateInitialSelections(with allUsers: [UserInfoModel]) {
        self.selectedProjectManager = allUsers.first { $0.name == self.selectedProjectManager?.name }
        let initialEmployeeMails = Set(self.selectedEmployees.map { $0.mail.lowercased() })
        self.selectedEmployees = allUsers.filter { initialEmployeeMails.contains($0.mail.lowercased()) }
        self.selectedCompany = availableCompanies.first { $0.companyName == self.companyName }
    }
}
