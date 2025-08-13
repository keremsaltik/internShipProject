//
//  CreateProjectTableViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 1.08.2025.
//

import UIKit

protocol EditProjectDelegate: AnyObject {
    func didUpdateProject()
}

class EditProjectTableViewController: UITableViewController, UITextViewDelegate{
    
    //MARK: - Variables
    // Storyboard'daki elemanlar için IBOutlet'ları oluştur
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var statusSegmentedControl: UISegmentedControl!
    @IBOutlet weak var prioritySegmentedControl: UISegmentedControl!
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var projectManagerButton: UIButton!
    @IBOutlet weak var companyButton: UIButton!
    @IBOutlet weak var employeesStackView: UIStackView!
    
    // Bu, bir önceki ekrandan (detay ekranı) gelen projeyi tutacak.
    var projectToEdit: ProjectModel?
    
    // Delegate'i tutacak değişken
    weak var delegate: EditProjectDelegate?
    
    // Menüler için veri kaynakları ve seçimleri tutan değişkenler
    var availableManagers: [UserViewModel] = []
    var availableUsers: [UserViewModel] = [] // API'den gelecek tüm kullanıcılar
    var selectedTeamMembers: [UserViewModel] = []
    var selectedManagerName: String?
    
    var selectedProjectManager: UserViewModel?
    var selectedCategory: String?
    
    
    
    var avaliableCompanies : [CompanyModel] = []
    var selectedCompany: CompanyModel?
    
    let descriptionPlaceHolder = "Proje açıklaması"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        Task{
            await fetchManagersandSetupMenu()
            //await fetchCategoriesandSetupMenu()
            await fetchCompaniesandSetupMenu()
            await fetchUsersAndPopulateStackView()
            // Gelen veriyle formu doldurmak için yeni bir fonksiyon çağıralım.
            populateForm()
        }
        
        
    }
    
    //MARK: - Actions
    // "Kaydet" butonuna basıldığında
    @IBAction func saveButtonTapped(_ sender: UIButton!){
        // 1. Güncellenecek projenin ID'sini ve temel verisini alalım.
        print("selectedTeamMembers: \(selectedTeamMembers.map { $0.mail })")
        guard var projectDataToUpdate = self.projectToEdit else{
            print("Güncellenecek proje verisi bulunamadı")
            return
        }
        
        // 2. Formdaki tüm alanlardan güncel verileri toplayalım.
        guard let title = titleTextField.text, !title.isEmpty,
              let description = descriptionTextView.text, !description.isEmpty, description != descriptionPlaceHolder,
              let projectManager = selectedManagerName,
              let category = selectedCategory,
              let company = selectedCompany else{
            AlertHelper.showAlert(viewController: self, title: "Eksik Bilgi", message: "Lütfen tüm alanları doldurun ve seçim yapın.")
            return
        }
        
        let startDate = startDatePicker.date
        let endDate = endDatePicker.date
        
        if endDate < startDate {
            AlertHelper.showAlert(viewController: self, title: "Geçersiz Tarih", message: "Proje bitiş tarihi, başlangıç tarihinden önce olamaz.")
            return
        }
        
        let status = statusSegmentedControl.titleForSegment(at: statusSegmentedControl.selectedSegmentIndex) ?? "Bilinmiyor"
        let priority = prioritySegmentedControl.titleForSegment(at: prioritySegmentedControl.selectedSegmentIndex) ?? "Bilinmiyor"
        
        
        let teamMembers = selectedTeamMembers.map{
            user in TeamMemberModel(userId: "", name: user.name, mail: user.mail)
        }
        
        let teamMembersMail = selectedTeamMembers.map { $0.mail }
        
        // 3. Modelimizi, formdaki yeni verilerle güncelleyelim.
        projectDataToUpdate.title = title
        projectDataToUpdate.description = description
        projectDataToUpdate.startDate = startDate
        projectDataToUpdate.endDate = endDate
        projectDataToUpdate.status = status
        projectDataToUpdate.category = category
        projectDataToUpdate.priority = priority
        projectDataToUpdate.projectManager = projectManager
        projectDataToUpdate.teamMembers = teamMembers
        projectDataToUpdate.company = company.companyName
        
        // 4. API isteğini yapmak için bir Task başlat
        Task{
            do{
                let response = try await APIService.shared.updateProject(projectData: projectDataToUpdate)
                if response.success {
                    DispatchQueue.main.async{ [weak self] in
                        guard let self = self else { return }
                        print(response.message ?? "Proje başarıyla güncellendi.")
                        
                        // Bir önceki ekrana haber vererek listeyi ve detayları yenilemesini sağlıyoruz.
                        self.delegate?.didUpdateProject()
                        
                        if self.navigationController == nil {
                            print("Bir navigation Controller bulunamadı")
                            
                        }else{
                            print("Navigation Controller bulundu. Yönlendiriliyor.")
                            self.dismiss(animated: true, completion: nil)
                        }
                        
                        
                        
                        
                    }
                }else{
                    DispatchQueue.main.async{ [weak self] in
                        guard let self = self else {
                            // Eğer self nil ise (yani kullanıcı bu işlem bitmeden ekranı kapattıysa),
                            // hiçbir şey yapma ve bu kod bloğundan güvenli bir şekilde çık.
                            return
                        }
                        
                        // 2. Artık bu bloğun içinde, 'self'in nil olmadığından eminiz.
                        // Bu yüzden onu güvenle kullanabiliriz.
                        AlertHelper.showAlert(viewController: self,
                                              title: "Güncelleme Başarısız",
                                              message: "Güncelleme yapılırken bir hata oluştu.")
                    }
                }
                
            }catch{
                DispatchQueue.main.async{ [weak self] in
                    print("Proje güncellenemedi: \(error.localizedDescription)")
                    guard let self = self else {
                        // Eğer self nil ise (yani kullanıcı bu işlem bitmeden ekranı kapattıysa),
                        // hiçbir şey yapma ve bu kod bloğundan güvenli bir şekilde çık.
                        return
                    }
                    
                    // 2. Artık bu bloğun içinde, 'self'in nil olmadığından eminiz.
                    // Bu yüzden onu güvenle kullanabiliriz.
                    AlertHelper.showAlert(viewController: self,
                                          title: "Güncelleme Başarısız",
                                          message: "Güncelleme yapılırken bir hata oluştu.")
                }
            }
        }
    }
    
    
    @IBAction func addEmployeeButtonTapped(_ sender: UIButton){
        guard let selectionViewController = storyboard?.instantiateViewController(withIdentifier: "EmployeesSelectionViewController") as? EmployeesSelectionViewController else {
                return
            }
            selectionViewController.previouslySelectedEmployees = self.selectedTeamMembers
            print("Sent Previously Selected Employees: \(self.selectedTeamMembers.map { $0.name })")
            
            selectionViewController.onDone = { [weak self] selectedEmployees in
                self?.selectedTeamMembers = selectedEmployees
                print("Closure ile seçilen çalışan sayısı: \(selectedEmployees.count)")
                self?.updateTeamMembersStackView()
            }
            let navController = UINavigationController(rootViewController: selectionViewController)
            present(navController, animated: true)
    }
    
    //MARK: - Functions
    
    // --- Proje Yöneticisi Menüsünü Ayarlama ---
    func fetchManagersandSetupMenu() async{
        do{
            let users = try await APIService.shared.fetchAllUsers()
            self.availableManagers = users
            
            
            DispatchQueue.main.async{
                self.setupManagerMenu()
            }
        }catch{
            print("Kullanıcı listesi çekilemedi: \(error.localizedDescription)")
            
            // Yönetici yoksa buton pasif duruma geçsin
            DispatchQueue.main.async{
                self.projectManagerButton.setTitle("Yönetici Yok", for: .normal)
            }
        }
        
    }
    
    // --- Kategori Menüsünü Ayarlama ---
    /*func fetchCategoriesandSetupMenu() async{
     do{
     let categories = try await APIService.shared.fetchCategories()
     self.availableCategories = categories
     
     DispatchQueue.main.async{
     self.setUpCategoryMenu()
     }
     }catch{
     print("Kategori listesi çekilemedi: \(error.localizedDescription)")
     
     DispatchQueue.main.async{
     self.categoryButton.setTitle("Kategori mevcut değil", for: .normal)
     }
     }
     }*/
    
    
    func setUpCategoryMenu(for company: CompanyModel) {
        
        let categoriesForCompany = company.categories
        
        
        let menuClosure = { [weak self] (action: UIAction) in
            guard let self = self else { return }
            self.selectedCategory = action.title
            self.categoryButton.setTitle(action.title, for: .normal)
        }
        
        let menuItems = categoriesForCompany.map { categoryName in
            UIAction(title: categoryName, handler: menuClosure)
        }
        
        categoryButton.menu = UIMenu(children: menuItems)
        categoryButton.showsMenuAsPrimaryAction = true
        
        // Eğer bir kategori zaten seçiliyse, onu menüde göster. Değilse, placeholder göster.
        if categoryButton.title(for: .normal) == nil || categoryButton.title(for: .normal) == "" {
            categoryButton.setTitle("Kategori Seçin", for: .normal)
        }
    }
    
    
    func setupManagerMenu() {
        let menuClosure = { [weak self] (action: UIAction) in
            guard let self = self else { return }
            self.selectedManagerName = action.title
            self.projectManagerButton.setTitle(action.title, for: .normal)
        }
        
        let menuItems = availableManagers.map { user in
            UIAction(title: user.name, handler: menuClosure)
        }
        
        projectManagerButton.menu = UIMenu(children: menuItems)
        projectManagerButton.showsMenuAsPrimaryAction = true
        
        // Eğer bir yönetici zaten seçiliyse, onu menüde göster. Değilse, placeholder göster.
        if projectManagerButton.title(for: .normal) == nil || projectManagerButton.title(for: .normal) == "" {
            projectManagerButton.setTitle("Yönetici Seçin", for: .normal)
        }
    }
    
    func fetchCompaniesandSetupMenu() async{
        do{
            let companies = try await APIService.shared.fetchAllCompanies()
            self.avaliableCompanies = companies
            
            DispatchQueue.main.async{
                self.setupCompanyMenu()
            }
        }catch{
            print("Şirket listesi çekilemedi: \(error.localizedDescription)")
            
            DispatchQueue.main.async{
                //self.categoryButton.setTitle("Şirket mevcut değil", for: .normal)
            }
        }
    }
    
    func setupCompanyMenu(){
        let menuClosure = { [weak self] (action: UIAction) in
            guard let self = self else { return }
            //self.selectedCompany = action.title
            //self.companyButton.setTitle(action.title, for: .normal)
            
            
            if let company = self.avaliableCompanies.first(where: {$0.companyName == action.title}){
                
                self.selectedCompany = company
                self.companyButton.setTitle(company.companyName, for: .normal)
                
                self.setUpCategoryMenu(for: company)
            }
        }
        
        let menuItems = avaliableCompanies.map{ company in
            UIAction(title: company.companyName, handler: menuClosure)
        }
        
        companyButton.menu = UIMenu(children: menuItems)
        companyButton.showsMenuAsPrimaryAction = true
        
        if categoryButton.title(for: .normal) == nil || categoryButton.title(for: .normal) == "" {
            categoryButton.setTitle("Kategori Seçin", for: .normal)
        }
        
    }
    
    func fetchUsersAndPopulateStackView() async {
        do {
            self.availableUsers = try await APIService.shared.fetchAllUsers()
            print("Available Users Count: \(availableUsers.count)")
            print("Available Users: \(availableUsers.map { $0.mail })")
            
            guard let teamMembers = projectToEdit?.teamMembers else {
                print("projectToEdit.teamMembers is nil or empty")
                DispatchQueue.main.async {
                    self.updateTeamMembersStackView()
                }
                return
            }
            print("Team Members: \(teamMembers.map { $0.mail })")
            
            self.selectedTeamMembers = teamMembers.compactMap { teamMember in
                let trimmedMail = teamMember.mail.trimmingCharacters(in: .whitespacesAndNewlines)
                if let user = self.availableUsers.first(where: { $0.mail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == trimmedMail.lowercased() }) {
                    print("Eşleşen kullanıcı bulundu: \(user.name) için \(trimmedMail)")
                    return user
                } else {
                    print("Eşleşmeyen e-posta: \(trimmedMail)")
                    return nil
                }
            }
            print("Selected Team Members: \(selectedTeamMembers.map { $0.name })")
            
            DispatchQueue.main.async {
                self.updateTeamMembersStackView()
            }
        } catch {
            print("Kullanıcı listesi çekilemedi: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.updateTeamMembersStackView()
            }
        }
    }
    
    // Bu fonksiyon, seçilen üyeleri alıp StackView'e UILabel olarak ekler.
    func updateTeamMembersStackView() {
        print("Selected Team Members: \(selectedTeamMembers.map { $0.name })")
        
        // Önce stackview'i temizle
        for subview in employeesStackView.arrangedSubviews {
            employeesStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        if selectedTeamMembers.isEmpty {
            let placeholderLabel = UILabel()
            placeholderLabel.text = "Çalışan seçilmedi"
            placeholderLabel.textColor = .placeholderText
            employeesStackView.addArrangedSubview(placeholderLabel)
            print("StackView: Placeholder eklendi")
        } else {
            for employee in selectedTeamMembers {
                let nameLabel = UILabel()
                nameLabel.text = employee.name
                nameLabel.font = .systemFont(ofSize: 14)
                nameLabel.textColor = .systemBlue
                employeesStackView.addArrangedSubview(nameLabel)
                print("StackView: \(employee.name) eklendi")
            }
        }
    }
    
    func populateForm(){
        guard let project = projectToEdit else { return }
        
        titleTextField.isEnabled = false
        titleTextField.textColor = .gray // Kullanıcıya düzenlenemez olduğunu belirtmek için
        titleTextField.text = project.title
        descriptionTextView.text = project.description
        
        // Segmented Control'leri ayarla
        if let statusIndex = ["Başlayacak", "Devam Ediyor", "Tamamlandı"].firstIndex(of: project.status) {
            statusSegmentedControl.selectedSegmentIndex = statusIndex
        }
        if let priorityIndex = ["Kritik", "Normal","Düşük"].firstIndex(of: project.priority) {
            prioritySegmentedControl.selectedSegmentIndex = priorityIndex
        }
        
        // Date Picker'ları dolduralım
        startDatePicker.date = project.startDate
        endDatePicker.date = project.endDate
        
        // Seçim değişkenlerini ve buton başlıklarını doldur
        selectedManagerName = project.projectManager
        projectManagerButton.setTitle(project.projectManager, for: .normal)
        
        selectedCategory = project.category
        categoryButton.setTitle(project.category, for: .normal)
        
        if let currentCompany = avaliableCompanies.first(where: {$0.companyName == project.company}){
            
            // Bulduğumuz tam 'CompanyModel' nesnesini 'selectedCompany' değişkenine atıyoruz.
            self.selectedCompany = currentCompany
            
            // Butonun başlığını da bu isimle güncelliyoruz.
            self.companyButton.setTitle(currentCompany.companyName, for: .normal)
            
            // Şirketi bulduğumuza göre, o şirkete ait kategorilerle menüyü de hemen kuralım.
            self.setUpCategoryMenu(for: currentCompany)
            
            // Ve son olarak, projenin orijinal kategorisini tekrar seçili hale getirelim.
            self.selectedCategory = project.category
            self.categoryButton.setTitle(project.category, for: .normal)
            
        }else {
            // Eğer bir sebepten dolayı projenin şirketi, mevcut şirketler listesinde bulunamazsa,
            // kullanıcıya bir seçim yapması gerektiğini belirtelim.
            companyButton.setTitle("Şirket Seçin", for: .normal)
            categoryButton.setTitle("Önce Şirket Seçin", for: .normal)
            categoryButton.isEnabled = false
        }
        
        
        
    }
}
