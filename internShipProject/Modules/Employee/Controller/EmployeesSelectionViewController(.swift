//
//  EmployeesSelectionViewController(.swift
//  internShipProject
//
//  Created by Kerem Saltık on 11.08.2025.
//

import UIKit

class EmployeesSelectionViewController: UITableViewController {
    
    lazy var viewModel = EmployeesSelectionViewModel(previouslySelectedEmployees: self.previouslySelectedEmployees)
        
        var previouslySelectedEmployees: [UserInfoModel] = []
    
    // Delegate değişkenini, bir closure değişkeniyle değiştiriyoruz.
    // Bu closure, bir [UserViewModel] dizisi alır ve hiçbir şey döndürmez.
    var onDone: (([UserInfoModel]) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
               
               // ViewModel'den veriyi çekmek için bir Task başlat.
               Task {
                   await fetchAndReloadData()
               }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return viewModel.availableEmployees.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                let user = viewModel.user(at: indexPath)
                
                var content = cell.defaultContentConfiguration()
                content.text = user.name
                cell.contentConfiguration = content
                
                if viewModel.isUserInitiallySelected(at: indexPath) {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
                
                return cell
    }
    
    /// ViewModel'den veriyi çeker ve tabloyu günceller. Hata durumunu yönetir.
        private func fetchAndReloadData() async {
            // İsteğe bağlı: Yükleme animasyonu başlatılabilir.
            
            do {
                // ViewModel'deki async fonksiyonun bitmesini bekle.
                try await viewModel.fetchAllUsers()
                
                // Başarılı olursa tabloyu yeniden yükle.
                // ViewModel @MainActor olduğu için bu satır zaten main thread'de çalışır.
                tableView.reloadData()
                
            } catch {
                // Hata olursa kullanıcıya uyarı göster.
                let errorMessage = "Kullanıcılar alınamadı: \(error.localizedDescription)"
                AlertHelper.showAlert(viewController: self, title: "Hata", message: errorMessage)
            }
            
            // İsteğe bağlı: Yükleme animasyonu durdurulabilir.
        }


    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem){
        var selectedUsers: [UserInfoModel] = []
                
                if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                    selectedUsers = selectedIndexPaths.map { viewModel.user(at: $0) }
                }
                
                onDone?(selectedUsers)
                dismiss(animated: true)
    }
    
    private func setupTableView() {
            tableView.isEditing = true
            tableView.allowsMultipleSelectionDuringEditing = true
        }
}
