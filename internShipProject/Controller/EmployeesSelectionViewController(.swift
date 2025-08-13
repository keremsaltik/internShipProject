//
//  EmployeesSelectionViewController(.swift
//  internShipProject
//
//  Created by Kerem Saltık on 11.08.2025.
//

import UIKit

class EmployeesSelectionViewController: UITableViewController {
    
    var avaliableEmployees: [UserViewModel] = []
    var previouslySelectedEmployees: [UserViewModel] = []
    
    // Delegate değişkenini, bir closure değişkeniyle değiştiriyoruz.
    // Bu closure, bir [UserViewModel] dizisi alır ve hiçbir şey döndürmez.
    var onDone: (([UserViewModel]) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.isEditing = true
        tableView.allowsMultipleSelectionDuringEditing = true
        
        Task{
           await fetchAllUsersandSetupMenu()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return avaliableEmployees.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        let user = avaliableEmployees[indexPath.row]
                var content = cell.defaultContentConfiguration()
                content.text = user.name
                cell.contentConfiguration = content
                
                // Önceki seçimleri kontrol et
                let isSelected = previouslySelectedEmployees.contains(where: {
                    $0.mail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                    user.mail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                })
                cell.accessoryType = isSelected ? .checkmark : .none
                if isSelected {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
        
        return cell
    }
    
    func fetchAllUsersandSetupMenu() async{
        do{
            let users = try await APIService.shared.fetchAllUsers()
            
            
            DispatchQueue.main.async{ [weak self] in
                guard let self = self else { return }
                
                self.avaliableEmployees = users
                
                tableView.reloadData()
            }
            
            
        }catch{
            print("Kullanıcı listesi çekilemedi: \(error.localizedDescription)")
        }
    }

    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem){
        var selectedUsers: [UserViewModel] = []
        
        // TableView'den o an seçili olan tüm satırların indexPath'lerini al.
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows{
            // Bu indexPath'leri kullanarak, seçilen 'UserViewModel' nesnelerini topla.
            selectedUsers = selectedIndexPaths.map{ indexPath in
                return avaliableEmployees[indexPath.row]
            }
        }
        
        onDone?(selectedUsers)
        
        dismiss(animated: true)
    }
}
