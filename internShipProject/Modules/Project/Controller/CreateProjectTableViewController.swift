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
    
    
    
    
    private let viewModel = CreateProjectViewModel()
    private let descriptionPlaceHolder = "Proje açıklaması"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Gerekli verileri çekmek için bir Task başlat
                Task {
                    do {
                        // ViewModel'den verileri çekmesini iste
                        try await viewModel.fetchInitialData()
                        // Veriler başarıyla geldikten sonra menüleri kur
                        setupAllMenus()
                    } catch {
                        // Hata olursa kullanıcıya göster
                        showErrorAlert(message: "Form verileri yüklenemedi: \(error.localizedDescription)")
                    }
                }
        
    }
    
    //MARK: - Actions
    
    // "Kaydet" butonuna basıldığında
    @IBAction func saveButtonTapped(_ sender: UIButton!){
        // Kaydetme işlemini ViewModel'e devret
                Task {
                    do {
                        try await viewModel.saveProject()
                        // Başarılı olursa bir önceki ekrana dön
                        navigationController?.popViewController(animated: true)
                    } catch {
                        // Hata olursa, ViewModel'in fırlattığı hatayı kullanıcıya göster
                        showErrorAlert(message: error.localizedDescription)
                    }
                }
    }
    
    
    
    @IBAction func addEmployeeButtonTapped(_ sender: UIButton){
        guard let selectionVC = storyboard?.instantiateViewController(withIdentifier: "EmployeesSelectionViewController") as? EmployeesSelectionViewController else { return }
                
                selectionVC.previouslySelectedEmployees = viewModel.selectedEmployees
                
                selectionVC.onDone = { [weak self] selectedEmployees in
                    self?.viewModel.selectedEmployees = selectedEmployees
                    self?.updateEmployeesStackView()
                }
                
                let navController = UINavigationController(rootViewController: selectionVC)
                present(navController, animated: true)
    }
    
    
    //MARK: - Functions
    
    private func setupUI() {
            descriptionTextView.delegate = self
            descriptionTextView.text = descriptionPlaceHolder
            descriptionTextView.textColor = .placeholderText
            
            categoryButton.isEnabled = false
            categoryButton.setTitle("Önce şirket seçin", for: .disabled)
            
            // Başlangıç değerlerini ViewModel'den al
            statusSegmentedControl.selectedSegmentIndex = 0 // "Beklemede"
            prioritySegmentedControl.selectedSegmentIndex = 1 // "Normal"
        }
    
    private func setupAllMenus() {
            setupCompanyMenu()
            setupManagerMenu()
            // Kategori menüsü, şirket seçildiğinde kurulacak.
        }
    
    private func setupCompanyMenu() {
            let menuItems = viewModel.availableCompanies.map { company in
                UIAction(title: company.companyName) { [weak self] _ in
                    self?.viewModel.selectedCompany = company
                    self?.companyButton.setTitle(company.companyName, for: .normal)
                    // Şirket seçildiğinde, ona ait kategorileri kur
                    self?.setupCategoryMenu(for: company)
                }
            }
            companyButton.menu = UIMenu(children: menuItems)
            companyButton.showsMenuAsPrimaryAction = true
        }
        
        private func setupManagerMenu() {
            let menuItems = viewModel.availableManagers.map { manager in
                UIAction(title: manager.name) { [weak self] _ in
                    self?.viewModel.selectedProjectManager = manager
                    self?.projectManagerButton.setTitle(manager.name, for: .normal)
                }
            }
            projectManagerButton.menu = UIMenu(children: menuItems)
            projectManagerButton.showsMenuAsPrimaryAction = true
        }
        
        private func setupCategoryMenu(for company: CompanyModel) {
            let categories = company.categories
            guard !categories.isEmpty else {
                categoryButton.isEnabled = false
                categoryButton.setTitle("Kategori Yok", for: .disabled)
                viewModel.selectedCategory = nil
                return
            }
            
            let menuItems = categories.map { categoryName in
                UIAction(title: categoryName) { [weak self] _ in
                    self?.viewModel.selectedCategory = categoryName
                    self?.categoryButton.setTitle(categoryName, for: .normal)
                }
            }
            
            categoryButton.menu = UIMenu(children: menuItems)
            categoryButton.showsMenuAsPrimaryAction = true
            categoryButton.isEnabled = true
            // Otomatik olarak ilk kategoriyi seç
            categoryButton.setTitle(categories.first, for: .normal)
            viewModel.selectedCategory = categories.first
        }
    
    // MARK: - UI Updates & Helpers
        
        private func updateEmployeesStackView() {
            employeesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            if viewModel.selectedEmployees.isEmpty {
                let placeholderLabel = UILabel()
                placeholderLabel.text = "Çalışan seçmek için dokunun"
                placeholderLabel.textColor = .placeholderText
                employeesStackView.addArrangedSubview(placeholderLabel)
            } else {
                viewModel.selectedEmployees.forEach { employee in
                    let nameLabel = UILabel()
                    nameLabel.text = employee.name
                    nameLabel.textColor = .systemBlue
                    employeesStackView.addArrangedSubview(nameLabel)
                }
            }
        }
        
        private func showErrorAlert(message: String) {
            let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
        }
        
        // MARK: - UITextViewDelegate
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == .placeholderText {
                textView.text = nil
                textView.textColor = .label
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = descriptionPlaceHolder
                textView.textColor = .placeholderText
            }
            viewModel.description = textView.text
        }
    
    
    
    
}
