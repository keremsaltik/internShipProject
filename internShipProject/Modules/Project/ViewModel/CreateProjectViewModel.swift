//
//  CreateProjectViewModel.swift
//  internShipProject
//
//  Created by Kerem Saltık on 11.09.2025.
//

import Foundation

@MainActor
class CreateProjectViewModel{
    // MARK: - Form Data Properties (ViewController tarafından güncellenecek)
        var title: String = ""
        var description: String = ""
        var startDate: Date = Date()
        var endDate: Date = Date()
        var status: String = "Beklemede" // Segmented control'ün ilk değeri
        var priority: String = "Normal"   // Segmented control'ün ilk değeri
        
        var selectedCategory: String?
        var selectedProjectManager: UserInfoModel?
        var selectedCompany: CompanyModel?
        var selectedEmployees: [UserInfoModel] = []
        
        // MARK: - Data Source Properties (API'den çekilecek)
        private(set) var availableManagers: [UserInfoModel] = []
        private(set) var availableCompanies: [CompanyModel] = []
    
    // MARK: - Custom Errors for Validation
    // Kendi hata türlerimizi tanımlayarak ViewController'da daha net hata mesajları gösterebiliriz.
    enum ValidationError: LocalizedError {
            case missingTitle
            case missingDescription
            case missingProjectManager
            case missingCategory
            case missingCompany
            case invalidDateRange
            case apiError(String)
            
            var errorDescription: String? {
                switch self {
                case .missingTitle: return "Lütfen proje başlığını girin."
                case .missingDescription: return "Lütfen proje açıklamasını girin."
                case .missingProjectManager: return "Lütfen bir proje yöneticisi seçin."
                case .missingCategory: return "Lütfen bir kategori seçin."
                case .missingCompany: return "Lütfen bir şirket seçin."
                case .invalidDateRange: return "Proje bitiş tarihi, başlangıç tarihinden önce olamaz."
                case .apiError(let message): return message
                }
            }
        }
    
    // MARK: - API Calls
        
    /// Form için gerekli olan başlangıç verilerini (şirketler, yöneticiler) çeker.
    func fetchInitialData() async throws {
           // async let ile iki isteği aynı anda (paralel) başlatarak zaman kazanırız.
           async let companies = APIService.shared.fetchAllCompanies()
           async let managers = APIService.shared.fetchAllUsers()
           
           // Her iki isteğin de bitmesini bekler ve sonuçları atarız.
           self.availableCompanies = try await companies
           self.availableManagers = try await managers
       }
       
       /// Form verilerini doğrular, API isteği oluşturur ve projeyi kaydeder.
       func saveProject() async throws {
           // 1. Adım: Girdileri doğrula
           try validateInputs()
           
           // 2. Adım: API Request Modelini Oluştur
           // `validateInputs` fonksiyonu guard'ları geçtiği için burada `!` kullanmak güvenlidir.
           let newProjectData = CreateProjectRequest(
               title: title,
               description: description,
               startDate: startDate,
               endDate: endDate,
               status: status,
               category: selectedCategory!,
               priority: priority,
               projectManager: selectedProjectManager!.name,
               employees: selectedEmployees.map { $0.mail },
               company: selectedCompany!.companyName
           )
           
           // 3. Adım: API isteğini yap
           let response = try await APIService.shared.createProject(projectData: newProjectData)
           
           // 4. Adım: API'den gelen yanıtı kontrol et
           if !response.success {
               throw ValidationError.apiError(response.message ?? "Proje oluşturulurken bilinmeyen bir hata oluştu.")
           }
       }
    
    // MARK: - Private Helper Functions
       
    /// Formdaki tüm girdilerin geçerli olup olmadığını kontrol eden özel fonksiyon.
    private func validateInputs() throws {
           guard !title.isEmpty else { throw ValidationError.missingTitle }
           guard !description.isEmpty, description != "Proje açıklaması" else { throw ValidationError.missingDescription }
           guard selectedProjectManager != nil else { throw ValidationError.missingProjectManager }
           guard selectedCategory != nil else { throw ValidationError.missingCategory }
           guard selectedCompany != nil else { throw ValidationError.missingCompany }
           guard endDate >= startDate else { throw ValidationError.invalidDateRange }
       }
}
