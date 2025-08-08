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
    
    // Bu, bir önceki ekrandan (detay ekranı) gelen projeyi tutacak.
       var projectToEdit: ProjectModel?
       
       // Delegate'i tutacak değişken
       weak var delegate: EditProjectDelegate?
       
       // Menüler için veri kaynakları ve seçimleri tutan değişkenler
       var availableManagers: [UserViewModel] = []
       var selectedManagerName: String?
       
       var availableCategories: [CategoryModel] = []
       var selectedCategory: String?
    
        let descriptionPlaceHolder = "Proje açıklaması"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpCategoryMenu()
        
        descriptionTextView.delegate = self
        descriptionTextView.text = descriptionPlaceHolder
        descriptionTextView.textColor = .placeholderText
        
        Task{
            await fetchManagersandSetupMenu()
            await fetchCategoriesandSetupMenu()
            // Gelen veriyle formu doldurmak için yeni bir fonksiyon çağıralım.
            populateForm()
        }
        
        
    }
    
    //MARK: - Actions
    // "Kaydet" butonuna basıldığında
    @IBAction func saveButtonTapped(_ sender: UIButton!){
        // 1. Güncellenecek projenin ID'sini ve temel verisini alalım.
        guard var projectDataToUpdate = self.projectToEdit else{
            print("Güncellenecek proje verisi bulunamadı")
            return
        }
        
        // 2. Formdaki tüm alanlardan güncel verileri toplayalım.
        guard let title = titleTextField.text, !title.isEmpty,
              let description = descriptionTextView.text, !description.isEmpty, description != descriptionPlaceHolder,
              let projectManager = selectedManagerName,
              let category = selectedCategory else{
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
        
        
        // 3. Modelimizi, formdaki yeni verilerle güncelleyelim.
            projectDataToUpdate.title = title
            projectDataToUpdate.description = description
            projectDataToUpdate.startDate = startDate
            projectDataToUpdate.endDate = endDate
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
    func fetchCategoriesandSetupMenu() async{
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
    }
    
    
    func setUpCategoryMenu() {
        let menuClosure = { [weak self] (action: UIAction) in
                    guard let self = self else { return }
                    self.selectedCategory = action.title
                    self.categoryButton.setTitle(action.title, for: .normal)
                }
                
                let menuItems = availableCategories.map { categoryName in
                    UIAction(title: categoryName.name, handler: menuClosure)
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
                
                // Date Picker'ları dolduralım
                startDatePicker.date = project.startDate
                endDatePicker.date = project.endDate
                
                // Seçim değişkenlerini ve buton başlıklarını doldur
                selectedManagerName = project.projectManager
                projectManagerButton.setTitle(project.projectManager, for: .normal)
                
                selectedCategory = project.category
                categoryButton.setTitle(project.category, for: .normal)
    
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
        
}

