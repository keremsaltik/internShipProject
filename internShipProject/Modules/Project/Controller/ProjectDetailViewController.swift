//
//  ProjectDetailViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 31.07.2025.
//

import UIKit


class ProjectDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, EditProjectDelegate {
    
    
  
    
    // MARK: - IBOutlets
    // Storyboard'dan gelen TableView'i buraya bağla
    @IBOutlet weak var tableView: UITableView!
    // MARK: - Properties
        var project: ProjectModel!
        private lazy var viewModel = ProjectDetailViewModel(project: project)
        
        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            
            setupTableView()
            updateUI()
        }
        
        // MARK: - UI Setup & Updates
        
        private func setupTableView() {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.tableFooterView = UIView()
        }
        
        private func updateUI() {
            self.title = viewModel.projectTitle
            tableView.reloadData()
        }
        
        // MARK: - IBActions
        
        @IBAction func shareButtonTapped(_ sender: UIButton) {
            guard let shareUrl = viewModel.getShareURL() else {
                print("Hata: Paylaşım URL'i oluşturulamadı")
                return
            }
            
            let activityViewController = UIActivityViewController(activityItems: [shareUrl], applicationActivities: nil)
            present(activityViewController, animated: true)
        }

        // MARK: - UITableViewDataSource
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return viewModel.detailItems.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
            let item = viewModel.detailItems[indexPath.row]
            
            var content = cell.defaultContentConfiguration()
            content.text = item.label
            content.textProperties.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            content.secondaryText = item.value
            content.secondaryTextProperties.color = .secondaryLabel
            
            if let iconName = item.iconName {
                content.image = UIImage(systemName: iconName)
            }
            
            if item.label == "Açıklama" {
                content.secondaryTextProperties.numberOfLines = 0
            }
            
            cell.contentConfiguration = content
            cell.selectionStyle = .none
            
            return cell
        }
        
        // MARK: - Navigation
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "editProjectSegue" {
                guard let navigationController = segue.destination as? UINavigationController,
                      let editVC = navigationController.topViewController as? EditProjectTableViewController else {
                    fatalError("Storyboard'da beklenmedik bir yapılandırma var.")
                }
                
                editVC.projectToEdit = viewModel.project
                editVC.delegate = self
            }
        }
        
        // MARK: - EditProjectDelegate
        
        /// Düzenleme ekranı kapandığında bu fonksiyon, güncellenmiş proje verisiyle tetiklenir.
    func didUpdateProject(project: ProjectModel) {
        // 1. ViewModel'i yeni proje verisiyle güncelle.
        viewModel.update(with: project)
        // 2. Arayüzü en son verilerle yenile.
        updateUI()
    }
}
