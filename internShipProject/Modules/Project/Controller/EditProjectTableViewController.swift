//
//  CreateProjectTableViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 1.08.2025.
//

import UIKit

protocol EditProjectDelegate: AnyObject {
    func didUpdateProject(project: ProjectModel)
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
    
    // MARK: - Properties
       var projectToEdit: ProjectModel!
       weak var delegate: EditProjectDelegate?
       
       private lazy var viewModel = EditProjectViewModel(project: projectToEdit)
       
       // MARK: - Lifecycle
       override func viewDidLoad() {
           super.viewDidLoad()
           
           Task {
               do {
                   try await viewModel.fetchInitialData()
                   setupUI()
               } catch {
                   showErrorAlert(message: "Gerekli veriler yüklenemedi: \(error.localizedDescription)")
               }
           }
       }
       
       // MARK: - UI Setup
       
       private func setupUI() {
           titleTextField.isEnabled = false
           titleTextField.textColor = .gray
           descriptionTextView.delegate = self
           
           titleTextField.text = viewModel.title
           descriptionTextView.text = viewModel.description
           startDatePicker.date = viewModel.startDate
           endDatePicker.date = viewModel.endDate
           
           if let statusIndex = ["Başlayacak", "Devam Ediyor", "Tamamlandı"].firstIndex(of: viewModel.status) {
               statusSegmentedControl.selectedSegmentIndex = statusIndex
           }
           if let priorityIndex = ["Kritik", "Normal", "Düşük"].firstIndex(of: viewModel.priority) {
               prioritySegmentedControl.selectedSegmentIndex = priorityIndex
           }
           
           setupAllMenus()
           updateEmployeesStackView()
       }
       
       private func setupAllMenus() {
           setupCompanyMenu()
           setupManagerMenu()
           
           if let company = viewModel.selectedCompany {
               companyButton.setTitle(company.companyName, for: .normal)
               setupCategoryMenu(for: company)
               categoryButton.setTitle(viewModel.selectedCategory, for: .normal)
           }
           
           if let manager = viewModel.selectedProjectManager {
               projectManagerButton.setTitle(manager.name, for: .normal)
           }
       }
       
       // MARK: - IBActions
       
       @IBAction func datePickerChanged(_ sender: UIDatePicker) {
           if sender == startDatePicker { viewModel.startDate = sender.date }
           else { viewModel.endDate = sender.date }
       }
       
       @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
           let title = sender.titleForSegment(at: sender.selectedSegmentIndex) ?? ""
           if sender == statusSegmentedControl { viewModel.status = title }
           else { viewModel.priority = title }
       }
       
       @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
           Task {
               do {
                   // 1. ViewModel'den güncellenmiş projeyi geri alıyoruz.
                   let updatedProject = try await viewModel.updateProject()
                   
                   // 2. Delegate'e güncellenmiş projeyi parametre olarak gönderiyoruz.
                   delegate?.didUpdateProject(project: updatedProject)
                   
                   // 3. Ekranı kapatıyoruz.
                   dismiss(animated: true)
               } catch {
                   showErrorAlert(message: error.localizedDescription)
               }
           }
       }
       
       @IBAction func addEmployeeButtonTapped(_ sender: UIButton) {
           guard let selectionVC = storyboard?.instantiateViewController(withIdentifier: "EmployeesSelectionViewController") as? EmployeesSelectionViewController else { return }
           
           selectionVC.previouslySelectedEmployees = viewModel.selectedEmployees
           selectionVC.onDone = { [weak self] selectedEmployees in
               self?.viewModel.selectedEmployees = selectedEmployees
               self?.updateEmployeesStackView()
           }
           
           let navController = UINavigationController(rootViewController: selectionVC)
           present(navController, animated: true)
       }
       
       // MARK: - Menu Setup & UI Updates
       
       private func setupCompanyMenu() {
           let menuItems = viewModel.availableCompanies.map { company in
               UIAction(title: company.companyName) { [weak self] _ in
                   self?.viewModel.selectedCompany = company
                   self?.companyButton.setTitle(company.companyName, for: .normal)
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
           let menuItems = company.categories.map { categoryName in
               UIAction(title: categoryName) { [weak self] _ in
                   self?.viewModel.selectedCategory = categoryName
                   self?.categoryButton.setTitle(categoryName, for: .normal)
               }
           }
           categoryButton.menu = UIMenu(children: menuItems)
           categoryButton.showsMenuAsPrimaryAction = true
           categoryButton.isEnabled = !company.categories.isEmpty
           if company.categories.isEmpty {
               categoryButton.setTitle("Kategori Yok", for: .disabled)
           }
       }
       
       private func updateEmployeesStackView() {
           employeesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
           
           if viewModel.selectedEmployees.isEmpty {
               let placeholderLabel = UILabel()
               placeholderLabel.text = "Çalışan seçilmedi"
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
       func textViewDidEndEditing(_ textView: UITextView) {
           viewModel.description = textView.text
       }
}
