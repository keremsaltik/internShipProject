//
//  EmployeeSelectionViewModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 11.09.2025.
//

import Foundation

@MainActor
class EmployeesSelectionViewModel {
    
    // MARK: - Properties
    
    // Sadece bu sınıf içinden değiştirilebilir, dışarıdan okunabilir.
    private(set) var availableEmployees: [UserInfoModel] = []
    
    private var previouslySelectedEmployees: [UserInfoModel] = []
    
    // MARK: - Initializer
    
    init(previouslySelectedEmployees: [UserInfoModel]) {
        self.previouslySelectedEmployees = previouslySelectedEmployees
    }
    
    // MARK: - Public Functions
    
    /// Sunucudan tüm kullanıcıları asenkron olarak çeker ve sınıfın kendi state'ini günceller.
    /// Başarısız olursa bir hata fırlatır.
    func fetchAllUsers() async throws {
        let users = try await APIService.shared.fetchAllUsers()
        self.availableEmployees = users
    }
    
    // MARK: - Helper Functions for TableView
    
    /// Belirtilen index'teki kullanıcıyı döndürür.
    func user(at indexPath: IndexPath) -> UserInfoModel {
        return availableEmployees[indexPath.row]
    }
    
    /// Bir kullanıcının başlangıçta seçili olup olmadığını kontrol eder.
    func isUserInitiallySelected(at indexPath: IndexPath) -> Bool {
        let currentUser = availableEmployees[indexPath.row]
        return previouslySelectedEmployees.contains { selectedUser in
            selectedUser.mail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
            currentUser.mail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
