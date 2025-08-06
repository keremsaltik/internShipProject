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

class EditProjectTableViewController: UITableViewController {
    
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
    
    // Bu, bir önceki ekrandan (detay ekranı) gelen projeyi tutacak.
       var projectToEdit: ProjectModel?
       
       // Delegate'i tutacak değişken
       weak var delegate: EditProjectDelegate?
       
       // Menüler için veri kaynakları ve seçimleri tutan değişkenler
       var availableManagers: [UserViewModel] = []
       var selectedManagerName: String?
       
       let availableCategories = ["Müşteri Deneyimi ve Dijital Bankacılık", "Ödeme ve Transfer Sistemleri", "Güvenlik ve Kimlik Doğrulama", "Kredi ve Finansman", "Veri Analitiği ve Raporlama", "Yatırım ve Varlık Yönetimi", "Regülasyon ve Uyumluluk", "Fintech Entegrasyonları", "Sürdürülebilirlik ve Sosyal Finans", "Operasyonel Verimlilik"]
       var selectedCategory: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpCategoryMenu()
        
        Task{
            await fetchManagersandSetupMenu()
            // Gelen veriyle formu doldurmak için yeni bir fonksiyon çağıralım.
            populateForm()
        }
        
        
    }
    
    // MARK: - Table view data source
    
    /*override func numberOfSections(in tableView: UITableView) -> Int {
     // #warning Incomplete implementation, return the number of sections
     return 0
     }
     
     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     // #warning Incomplete implementation, return the number of rows
     return 0
     }*/
    
    //MARK: - Actions
    
    /*// "İptal" butonuna basıldığında
     @IBAction func cancelButtonTapped(_ sender: UIButton!){
     dismiss(animated: true)
     }*/
    
    // "Kaydet" butonuna basıldığında
    @IBAction func saveButtonTapped(_ sender: UIButton!){
        // 1. Güncellenecek projenin ID'sini ve temel verisini alalım.
        guard var projectDataToUpdate = self.projectToEdit else{
            print("Güncellenecek proje verisi bulunamadı")
            return
        }
        
        // 2. Formdaki tüm alanlardan güncel verileri toplayalım.
        guard let title = titleTextField.text, !title.isEmpty,
              let description = descriptionTextView.text, !description.isEmpty,
              let projectManager = selectedManagerName,
              let category = selectedCategory else{
            showAlert(title: "Eksik bilgi.", message: "Lütfen tüm alanları doldurun ve seçim yapın.")
            return
        }
        
        let startDate = startDatePicker.date
        let endDate = endDatePicker.date
        
        if endDate < startDate {
                    showAlert(title: "Geçersiz Tarih", message: "Proje bitiş tarihi, başlangıç tarihinden önce olamaz.")
                    return
                }
        
        let status = statusSegmentedControl.titleForSegment(at: statusSegmentedControl.selectedSegmentIndex) ?? "Bilinmiyor"
                let priority = prioritySegmentedControl.titleForSegment(at: prioritySegmentedControl.selectedSegmentIndex) ?? "Bilinmiyor"
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startDateString = isoFormatter.string(from: startDate)
        let endDateString = isoFormatter.string(from: endDate)
        
        // 3. Modelimizi, formdaki yeni verilerle güncelleyelim.
            projectDataToUpdate.title = title
            projectDataToUpdate.description = description
            projectDataToUpdate.startDate = startDateString
            projectDataToUpdate.endDate = endDateString
            projectDataToUpdate.status = status
            projectDataToUpdate.category = category
            projectDataToUpdate.priority = priority
            projectDataToUpdate.projectManager = projectManager
               
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
                        self?.showAlert(title: "Güncelleme Başarısız.", message: response.message ?? "Güncelleme yapılırken bir hata oluştu.")
                    }
                }
            }catch{
                DispatchQueue.main.async{ [weak self] in
                    print("Proje güncellenemedi: \(error.localizedDescription)")
                    self?.showAlert(title: "Ağ hatası", message: "Sunucuya bağlanılamadı")
                }
            }
        }
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
    func setUpCategoryMenu() {
        let menuClosure = { [weak self] (action: UIAction) in
                    guard let self = self else { return }
                    self.selectedCategory = action.title
                    self.categoryButton.setTitle(action.title, for: .normal)
                }
                
                let menuItems = availableCategories.map { categoryName in
                    UIAction(title: categoryName, handler: menuClosure)
                }
                
                categoryButton.menu = UIMenu(children: menuItems)
                categoryButton.showsMenuAsPrimaryAction = true
                
                // Eğer bir kategori zaten seçiliyse, onu menüde göster. Değilse, placeholder göster.
                if categoryButton.title(for: .normal) == nil || categoryButton.title(for: .normal) == "" {
                    categoryButton.setTitle("Kategori Seçin", for: .normal)
                }
    }
        
        //MARK: - Helper Functions
        
        // Uyarıları göstermek için yardımcı bir fonksiyon
        func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
            present(alert, animated: true)
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
                if let priorityIndex = ["Düşük", "Normal", "Yüksek", "Kritik"].firstIndex(of: project.priority) {
                    prioritySegmentedControl.selectedSegmentIndex = priorityIndex
                }
                
                // Date Picker'ları ayarla
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let startDate = isoFormatter.date(from: project.startDate) {
                    startDatePicker.date = startDate
                }
                if let endDate = isoFormatter.date(from: project.endDate) {
                    endDatePicker.date = endDate
                }
                
                // Seçim değişkenlerini ve buton başlıklarını doldur
                selectedManagerName = project.projectManager
                projectManagerButton.setTitle(project.projectManager, for: .normal)
                
                selectedCategory = project.category
                categoryButton.setTitle(project.category, for: .normal)
    
    }
        
}

