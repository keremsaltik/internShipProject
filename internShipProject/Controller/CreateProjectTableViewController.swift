//
//  CreateProjectTableViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 1.08.2025.
//

import UIKit

class CreateProjectTableViewController: UITableViewController {
    
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
    
    
    var selectedManager: UserViewModel?
    var selectedCategory: String?
    
    var availableManagers : [UserViewModel] = []
    let avaliableCategories = ["Müşteri Deneyimi ve Dijital Bankacılık","Ödeme ve Transfer Sistemleri","Güvenlik ve Kimlik Doğrulama", "Kredi ve Finansman", "Veri Analitiği ve Raporlama", "Yatırım ve Varlık Yönetimi", "Regülasyon ve Uyumluluk", "Fintech Entegrasyonları", "Sürdürülebilirlik ve Sosyal Finans", "Operasyonel Verimlilik"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpCategoryMenu()
        
        Task{
            await fetchManagersandSetupMenu()
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
        print("--- KAYDET BUTONUNA BASILDI ---")
        // 1. Alanlardan veriyi topla ve boş olup olmadığını kontrol et
        guard let title = titleTextField.text, !title.isEmpty,
              let description = descriptionTextView.text, !description.isEmpty
        else {
            // Kullanıcıya bir uyarı göster
            showAlert(title: "Eksik Bilgi", message: "Lütfen başlık ve açıklama alanlarını doldurun.")
            return
        }
        guard let projectManager = selectedManager?.name else {
                   showAlert(title: "Eksik Bilgi", message: "Lütfen bir proje yöneticisi seçin.")
                   return
        }
        
        guard let category = selectedCategory else {
               showAlert(title: "Eksik Bilgi", message: "Lütfen bir kategori seçin.")
               return
           }
        // 2. Seçili tarihleri al
        let startDate = startDatePicker.date
        let endDate = endDatePicker.date
        
        // Bitiş tarihinin başlangıç tarihinden önce olup olmadığını kontrol et
        if endDate < startDate {
            showAlert(title: "Geçersiz Tarih", message: "Proje bitiş tarihi, başlangıç tarihinden önce olamaz.")
            return
        }
        
        // 3. Seçili durumu (status) al
        let statusIndex = statusSegmentedControl.selectedSegmentIndex
        // Segmented Control'deki başlıkları doğrudan alıyoruz.
        let status = statusSegmentedControl.titleForSegment(at: statusIndex) ?? "Bilinmiyor"
        
        // 4. Tarihleri backend'in beklediği ISO8601 formatındaki String'e çevir
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startDateString = isoFormatter.string(from: startDate)
        let endDateString = isoFormatter.string(from: endDate)
        
        
        // Öncelik değeri
        let priorityIndex = prioritySegmentedControl.selectedSegmentIndex
        
        let priority = prioritySegmentedControl.titleForSegment(at: priorityIndex) ??  "Bilinmiyor"
        
        // 5. API'ye gönderilecek istek modelini oluştur
        let newProjectData = CreateProjectRequest(
            title: title,
            description: description,
            startDate: startDateString,
            endDate: endDateString,
            status: status,
            category: category,
            priority: priority,
            projectManager: projectManager
            
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
                        self.showAlert(title: "Kayıt Başarısız", message: response.message ?? "Proje oluşturulurken bir hata oluştu.")
                    }
                }
            } catch {
                // Ağ hatası veya başka bir sorun.
                DispatchQueue.main.async {
                    print("Proje oluşturulamadı: \(error.localizedDescription)")
                    self.showAlert(title: "Ağ Hatası", message: "Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.")
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
        // 1. ADIM: Kullanıcı bir seçim yaptığında ne olacağını tanımla.
        let menuClosure = { [weak self] (action: UIAction) in
            guard let self = self else { return }
            
            self.selectedCategory = action.title
            self.categoryButton.setTitle(action.title, for: .normal)
        }
        
        // 2. ADIM: Veri kaynağından menü elemanlarını oluştur.
        let menuItems = avaliableCategories.map { categoryName in
            UIAction(title: categoryName, handler: menuClosure)
        }
        
        // 3. ADIM: Menüyü oluştur ve butona ata.
        categoryButton.menu = UIMenu(children: menuItems)
        categoryButton.showsMenuAsPrimaryAction = true
        
        // 4. ADIM: Başlangıç durumunu ayarla.
        categoryButton.setTitle("Kategori Seçin", for: .normal)
        selectedCategory = nil
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
            
            // Seçilen yöneticinin tam nesnesini bulalım.
            if let manager = self.availableManagers.first(where: { $0.name == action.title }) {
                self.selectedManager = manager
                self.projectManagerButton.setTitle(manager.name, for: .normal)
            }
        }
        
        // API'den gelen 'availableManagers' dizisini kullanarak menüyü oluştur.
        let menuItems = availableManagers.map { user in
            UIAction(title: user.name, handler: menuClosure)
        }
        
        projectManagerButton.menu = UIMenu(children: menuItems)
        projectManagerButton.showsMenuAsPrimaryAction = true
        
        // Başlangıç durumunu ayarla.
        if let firstManager = availableManagers.first {
            projectManagerButton.setTitle(firstManager.name, for: .normal)
            selectedManager = firstManager
        } else {
            projectManagerButton.setTitle("Yönetici Seçin", for: .normal)
        }
    }
        
}

