//
//  CreateProjectTableViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 1.08.2025.
//

import UIKit

class CreateProjectTableViewController: UITableViewController, UITextViewDelegate {
    
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
    
    
    
    
    var availableManagers : [UserViewModel] = []
    var avaliableCompanies : [CompanyModel] = []
    
    var selectedProjectManager: UserViewModel?
    var selectedCategory: String?
    var selectedCompany: CompanyModel?
    var selectedTeamMembers: [UserViewModel] = []
    
    
    
    
    
    let menuManager = MenuManager()
    let descriptionPlaceHolder = "Proje açıklaması"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descriptionTextView.delegate = self
        descriptionTextView.text = descriptionPlaceHolder
        descriptionTextView.textColor = .placeholderText
        
        categoryButton.isEnabled = false
        categoryButton.setTitle("Lütfen bir şirket seçiniz", for: .disabled)
        
        
        Task{
            
            //await fetchCategoriesandSetupMenu()
            await fetchCompaniesAndSetupMenu()
            await fetchManagersandSetupMenu()
            
            
        }
        
    }
    
    //MARK: - Actions
    
    // "Kaydet" butonuna basıldığında
    @IBAction func saveButtonTapped(_ sender: UIButton!){
        print("--- KAYDET BUTONUNA BASILDI ---")
        // 1. Alanlardan veriyi topla ve boş olup olmadığını kontrol et
        guard let title = titleTextField.text, !title.isEmpty,
              let description = descriptionTextView.text, !description.isEmpty, description != descriptionPlaceHolder
        else {
            // Kullanıcıya bir uyarı göster
            AlertHelper.showAlert(viewController: self, title: "Eksik Bilgi", message: "Lütfen başlık ve açıklama alanlarını doldurun.")
            return
        }
        
        guard let projectManager = selectedProjectManager?.name else {
            AlertHelper.showAlert(viewController: self, title: "Eksik Bilgi", message: "Lütfen bir proje yöneticisi seçin.")
            return
        }
        
        guard let category = selectedCategory else {
            AlertHelper.showAlert(viewController: self, title: "Eksik Bilgi", message: "Lütfen bir kategori seçin.")
            return
        }
        
        
        // 2. Seçili tarihleri al
        let startDate = startDatePicker.date
        let endDate = endDatePicker.date
        
        // Bitiş tarihinin başlangıç tarihinden önce olup olmadığını kontrol et
        if endDate < startDate {
            AlertHelper.showAlert(viewController: self, title: "Geçersiz Tarih" , message: "Proje bitiş tarihi, başlangıç tarihinden önce olamaz.")
            return
        }
        
        // 3. Seçili durumu (status) al
        let statusIndex = statusSegmentedControl.selectedSegmentIndex
        // Segmented Control'deki başlıkları doğrudan alıyoruz.
        let status = statusSegmentedControl.titleForSegment(at: statusIndex) ?? "Bilinmiyor"
        
        
        
        // Öncelik değeri
        let priorityIndex = prioritySegmentedControl.selectedSegmentIndex
        
        let priority = prioritySegmentedControl.titleForSegment(at: priorityIndex) ??  "Bilinmiyor"
        
        guard let company = selectedCompany else{
            AlertHelper.showAlert(viewController: self, title: "Eksik Bilgi", message: "Lütfen bir şirket seçin.")
            return
        }
        
        let teamMembersMail = selectedTeamMembers.map { $0.mail }
        // 5. API'ye gönderilecek istek modelini oluştur
        let newProjectData = CreateProjectRequest(
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            status: status,
            category: category,
            priority: priority,
            projectManager: projectManager,
            teamMembers: teamMembersMail,
            company: company.companyName
            
            
        )
        
        // 6. API isteğini yapmak için bir Task başlat
        Task {
            do {
                let response = try await APIService.shared.createProject(projectData: newProjectData)
                
                if response.success {
                    // Başarılı: Ekranı kapat.
                    // UI işlemleri her zaman ana thread'de yapılmalıdır.
                    DispatchQueue.main.async {
                        print(response.message ?? "Proje başarıyla eklendi.")
                        // (İsteğe bağlı) Bir önceki ekrana haber vererek listeyi yenilemesini sağlayabilirsin.
                        self.navigationController?.popViewController(animated: true)
                    }
                } else {
                    // Backend'den gelen özel bir hata mesajı varsa onu göster.
                    DispatchQueue.main.async {
                        AlertHelper.showAlert(viewController: self, title: "Kayıt Başarısız", message: response.message ?? "Proje oluşturulurken bir hata oluştu")
                        //self.showAlert(title: "Kayıt Başarısız", message: response.message ?? "Proje oluşturulurken bir hata oluştu.")
                    }
                }
            } catch {
                // Ağ hatası veya başka bir sorun.
                DispatchQueue.main.async {
                    print("Proje oluşturulamadı: \(error.localizedDescription)")
                    AlertHelper.showAlert(viewController: self, title: "Ağ Hatası", message: "Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.")
                }
            }
        }
    }
    
    
    
    @IBAction func addEmployeeButtonTapped(_ sender: UIButton){
        guard let selectionViewController = storyboard?.instantiateViewController(withIdentifier: "EmployeesSelectionViewController") as? EmployeesSelectionViewController else {
            return
        }
        
        
        // Halihazırda seçili olanları, seçim ekranına gönderiyoruz.
        selectionViewController.previouslySelectedEmployees = self.selectedTeamMembers
        
        // --- DEĞİŞİKLİK BURADA ---
        // 'delegate' atamak yerine, 'onDone' closure'ını tanımlıyoruz.
        // Bu, "Seçim ekranı kapandığında ve 'onDone' çağrıldığında ne yapılacağını" söyler.
        selectionViewController.onDone = { [weak self] selectedEmployees in
            
            self?.selectedTeamMembers = selectedEmployees
            
            // Arayüzü güncelle
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
    
    func setUpCategoryMenu(for company: CompanyModel) {
        let categoriesForCompany = company.categories
        print("Categories for \(company.companyName): \(categoriesForCompany)")
        
        if categoriesForCompany.isEmpty {
            categoryButton.setTitle("Kategori Yok", for: .normal)
            categoryButton.isEnabled = false
            categoryButton.menu = nil
            selectedCategory = nil
            return
        }
        
        let menuItems = categoriesForCompany.map { categoryName in
            UIAction(title: categoryName) { [weak self] _ in
                self?.selectedCategory = categoryName
                self?.categoryButton.setTitle(categoryName, for: .normal)
            }
        }
        
        categoryButton.menu = UIMenu(children: menuItems)
        categoryButton.showsMenuAsPrimaryAction = true
        categoryButton.setTitle(categoriesForCompany.first ?? "Kategori Seçin", for: .normal)
        selectedCategory = categoriesForCompany.first
        categoryButton.isEnabled = true
    }
    
    func setupManagerMenu() {
        if availableManagers.isEmpty {
            projectManagerButton.setTitle("Yönetici Yok", for: .normal)
            projectManagerButton.isEnabled = false
            projectManagerButton.menu = nil
            selectedProjectManager = nil
            return
        }
        
        let menuClosure = { [weak self] (action: UIAction) in
            guard let self = self else { return }
            
            if let manager = self.availableManagers.first(where: { $0.name == action.title }) {
                self.selectedProjectManager = manager
                self.projectManagerButton.setTitle(manager.name, for: .normal)
            }
        }
        
        let menuItems = availableManagers.map { user in
            UIAction(title: user.name, handler: menuClosure)
        }
        
        projectManagerButton.menu = UIMenu(children: menuItems)
        projectManagerButton.showsMenuAsPrimaryAction = true
        projectManagerButton.setTitle(availableManagers.first?.name ?? "Yönetici Seçin", for: .normal)
        selectedProjectManager = availableManagers.first
        projectManagerButton.isEnabled = true
    }
    
    
    
    
    func fetchCompaniesAndSetupMenu() async {
        do {
            let companies = try await APIService.shared.fetchAllCompanies()
            self.avaliableCompanies = companies
            DispatchQueue.main.async {
                self.setupCompanyMenu()
            }
        } catch {
            print("Şirket listesi çekilemedi: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.companyButton.setTitle("Şirket Yok", for: .normal)
            }
        }
    }
    
    func setupCompanyMenu() {
        let menuClosure = { [weak self] (action: UIAction) in
            guard let self = self else { return }
            
            if let company = self.avaliableCompanies.first(where: { $0.companyName == action.title }) {
                self.selectedCompany = company
                self.companyButton.setTitle(company.companyName, for: .normal)
                
                // DEĞİŞİKLİK: Artık yeni bir API isteği yapmıyoruz.
                // Sadece kategori menüsünü güncelliyoruz.
                self.setUpCategoryMenu(for: company)
            }
        }
        
        // ... (fonksiyonun geri kalanı aynı kalır)
        let menuItems = avaliableCompanies.map { company in
            UIAction(title: company.companyName, handler: menuClosure)
        }
        companyButton.menu = UIMenu(children: menuItems)
        companyButton.showsMenuAsPrimaryAction = true
        companyButton.setTitle("Şirket Seçin", for: .normal)
        selectedCompany = nil
    }
    
    // Bu yeni fonksiyon, zincirleme reaksiyonu yönetir.
    func updateDependentMenus(for company: CompanyModel) {
        // Kategori menüsünü anında kur (senkron işlem)
        setUpCategoryMenu(for: company)
        
        // Yönetici menüsü için API isteği yap
        projectManagerButton.setTitle("Yöneticiler Yükleniyor...", for: .normal)
        projectManagerButton.isEnabled = false
        
        Task {
            await fetchManagersandSetupMenu()
        }
    }
    
    
    // Kullanıcı TextView'in içine tıkladığında...
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText{
            textView.text = nil
            textView.textColor = .label // Normal metin rengi
        }
    }
    
    // Kullanıcı TextView'den çıktığında...
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty{
            textView.text = descriptionPlaceHolder
            textView.textColor = .placeholderText
        }
    }
    
    //StackView güncelleme fonksiyonu
    func updateTeamMembersStackView() {
        // 1. Önce, stackview'in içindeki tüm eski etiketleri temizle.
        for subview in employeesStackView.arrangedSubviews {
            employeesStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        // 2. Eğer hiç çalışan seçilmemişse, bir placeholder göster ve bitir.
        if selectedTeamMembers.isEmpty {
            let placeholderLabel = UILabel()
            placeholderLabel.text = "Çalışan seçmek için dokunun"
            placeholderLabel.textColor = .placeholderText
            employeesStackView.addArrangedSubview(placeholderLabel)
            return // Fonksiyondan çık
        }
        
        // 3. Eğer seçilmiş çalışanlar VARSA, her biri için bir etiket oluştur.
        for employee in selectedTeamMembers {
            let nameLabel = UILabel()
            nameLabel.text = employee.name
            nameLabel.font = .systemFont(ofSize: 14)
            nameLabel.textColor = .systemBlue
            
            // StackView'e bu yeni etiketi ekle.
            employeesStackView.addArrangedSubview(nameLabel)
        }
    }
    
    
    
    
}
