//
//  ProjectTableViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 30.07.2025.
//

import UIKit

class ProjectTableViewController: UITableViewController, UISearchBarDelegate {

    
    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: - Properties
        private let viewModel = ProjectListViewModel()
        private let feedBackGenerator = UINotificationFeedbackGenerator()
        
        // MARK: - Life Cycle
        override func viewDidLoad() {
            super.viewDidLoad()
            searchBar.delegate = self
            setupRefreshControl()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // Her ekrana gelindiğinde verileri yenile.
            fetchData()
        }

        // MARK: - Data Fetching & Handling
        
        private func fetchData() {
            if refreshControl?.isRefreshing == false {
                refreshControl?.beginRefreshing()
            }
            
            Task {
                do {
                    try await viewModel.fetchProjects()
                    tableView.reloadData()
                } catch {
                    handle(error: error)
                }
                refreshControl?.endRefreshing()
            }
        }
        
        private func handle(error: Error) {
            var errorMessage = "Bilinmeyen bir hata oluştu."
            
            // --- HATA BURADAYDI, DÜZELTİLDİ ---
            // 'apiError == .unauthorized' yerine 'case .unauthorized = apiError' kullanıyoruz.
            if let apiError = error as? APIError, case .unauthorized = apiError {
                errorMessage = "Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın."
                AlertHelper.showAlert(viewController: self, title: "Hata", message: errorMessage) {
                    self.logOutAndGoToLogin()
                }
            } else {
                errorMessage = "Lütfen internet bağlantınızı kontrol edin veya daha sonra tekrar deneyin."
                AlertHelper.showAlert(viewController: self, title: "Hata", message: errorMessage)
            }
        }
        
        // MARK: - UI Setup
        
        private func setupRefreshControl() {
            let refreshController = UIRefreshControl()
            refreshController.addTarget(self, action: #selector(refreshData), for: .valueChanged)
            self.refreshControl = refreshController
        }

        // MARK: - Actions
        
        @objc private func refreshData() {
            fetchData()
        }
        
        // MARK: - Table view data source

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return viewModel.visibleProjects.count
        }
        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath)
            let project = viewModel.visibleProjects[indexPath.row]
            
            var content = cell.defaultContentConfiguration()
            content.text = project.title
            content.secondaryText = project.status
            cell.contentConfiguration = content
            
            return cell
        }
        
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                Task {
                    do {
                        try await viewModel.deleteProject(at: indexPath)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        feedBackGenerator.notificationOccurred(.success)
                    } catch {
                        AlertHelper.showAlert(viewController: self, title: "Hata", message: "Proje silinirken bir sorun oluştu.")
                    }
                }
            }
        }

        // MARK: - Navigation
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showProjectDetail" {
                guard let detailVC = segue.destination as? ProjectDetailViewController,
                      let indexPath = tableView.indexPathForSelectedRow else { return }
                
                detailVC.project = viewModel.visibleProjects[indexPath.row]
            }
        }
        
        // MARK: - UISearchBarDelegate
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            viewModel.filter(with: searchText)
            tableView.reloadData()
        }
        
        // MARK: - EditProjectDelegate
        
        func didUpdateProject(project: ProjectModel) {
            fetchData()
        }
        
        // MARK: - Routing
        
        private func logOutAndGoToLogin() {
            KeyChainManager.shared.deleteToken()
            switchToLoginScreen()
        }
        
        private func switchToLoginScreen() {
            guard let loginNavController = self.storyboard?.instantiateViewController(withIdentifier: "toLoginPageNavigationController") else {
                print("Hata: toLoginPageNavigationController storyboard'da bulunamadı.")
                return
            }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate,
               let window = sceneDelegate.window {
                window.rootViewController = loginNavController
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            }
        }
}
