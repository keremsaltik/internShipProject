//
//  ProjectTableViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 30.07.2025.
//

import UIKit

class ProjectTableViewController: UITableViewController, UISearchBarDelegate {

    //MARK: - Variables
    // 1. ADIM: Veri Kaynağını Oluştur
    // Bu dizi, API'den gelen projeleri tutacak.
    var projects: [ProjectModel] = []
    var project: ProjectModel?
    var filteredProjects: [ProjectModel] = []
    
    let refreshController = UIRefreshControl()
    let feedBackGenerator = UINotificationFeedbackGenerator()
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Arama çubuğunun delegate'ini bu sınıfa ata.
        // Bu, "kullanıcı bir şey yazdığında bana haber ver" demektir.
        searchBar.delegate = self
        
        refreshController.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Task{
            refreshController.beginRefreshing()
            await fetcUserProjects()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return filteredProjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Storyboard'da hücrene verdiğin identifier'ı kullan.
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath)
        
        // O anki satır için doğru projeyi diziden al.
        let project = filteredProjects[indexPath.row]
        
        // Hücreyi proje verileriyle doldur.
        // Standart bir hücre stili (örn: Subtitle) kullandığını varsayıyorum.
        cell.textLabel?.text = project.title
        cell.detailTextLabel?.text = project.status
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProject = filteredProjects[indexPath.row]
        performSegue(withIdentifier: "showProjectDetail", sender: selectedProject)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true // Bu sayede tüm satırlar editlenebilir.
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let projectToDelete = filteredProjects[indexPath.row]
            let projectTitle = projectToDelete.title
            
            Task {
                do {
                    // API'ye silme isteği gönder.
                    try await APIService.shared.deleteProject(projectTitle: projectTitle)
                    
                    // Başarılı: UI'ı ana thread'de güncelle.
                    DispatchQueue.main.async { [weak self] in
                        
                        guard let self = self else{
                            return
                        }
                        
                        // Projeyi, filtrelenmiş listeden sil.
                        self.filteredProjects.remove(at: indexPath.row)
                        
                        // Projeyi, ana kopyamız olan 'projects' dizisinden de bulup silmeliyiz!
                        // Bu, arama temizlendiğinde silinen projenin geri gelmesini engeller.
                        
                        if let indexAllInProjects = self.projects.firstIndex(where: {$0.id == projectToDelete.id}){
                            self.projects.remove(at: indexAllInProjects)
                        }
                        
                        // 2. ADIM: SONRA arayüze (TableView'e) bu değişikliği yansıtmasını söyle.
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        feedBackGenerator.notificationOccurred(.success)
                    }
                    
                } catch {
                    // Hata: Kullanıcıya bir uyarı göster.
                    DispatchQueue.main.async {
                        print("Proje silinemedi: \(error.localizedDescription)")
                        AlertHelper.showAlert(viewController: self, title: "Hata", message: "Proje silinirken bir sorun oluştu.")
                    }
                }
            }
        }
    }


    
    // MARK: - Functions
    
    // 2. ADIM: API İsteği Yapan Fonksiyonu Ekle
    func fetcUserProjects() async{
        
        if !refreshController.isRefreshing {
                    DispatchQueue.main.async {
                        self.refreshController.beginRefreshing()
                    }
                }
        
        do{
            // APIService'den projeleri çekiyoruz.
            let fetchedProjects = try await APIService.shared.fetchProjects()
            
            // Başarılı: UI'ı (TableView'i) ana thread'de güncelliyoruz.
            DispatchQueue.main.async {
                self.projects = fetchedProjects
                self.filteredProjects = fetchedProjects
                self.tableView.reloadData() // TableView'e "verilerim değişti, kendini yeniden çiz" diyoruz.
                
                self.refreshController.endRefreshing() // Veriler alındığında çark dursun
            }
            
        }catch{
            // Hata: Kullanıcıya bir uyarı gösteriyoruz.
            // --- DAHA DETAYLI HATA AYIKLAMA ---
                /*print("HATA YAKALANDI: \(error.localizedDescription)")

                // Hatanın bir DecodingError olup olmadığını kontrol et
                if let decodingError = error as? DecodingError {
                    print("--- DECODING HATASI DETAYLARI ---")
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("Tip Uyuşmazlığı: '\(type)' tipi bekleniyordu ama başka bir şey geldi.")
                        print("Kodlama Yolu: \(context.codingPath)")
                        print("Açıklama: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Değer Bulunamadı: '\(type)' tipi için bir değer bekleniyordu ama null veya eksik geldi.")
                        print("Kodlama Yolu: \(context.codingPath)")
                        print("Açıklama: \(context.debugDescription)")
                    case .keyNotFound(let key, let context):
                        print("Anahtar Bulunamadı: '\(key.stringValue)' anahtarı JSON'da bulunamadı.")
                        print("Kodlama Yolu: \(context.codingPath)")
                        print("Açıklama: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Veri Bozuk: JSON formatı geçerli değil.")
                        print("Kodlama Yolu: \(context.codingPath)")
                        print("Açıklama: \(context.debugDescription)")
                    @unknown default:
                        fatalError()
                    }
                    print("---------------------------------")
                }*/
            
            
            DispatchQueue.main.async {
                [weak self] in
                
                guard let self = self else{ return }
                
                var errorMessage = "Bilinmeyen bir hata oluştu."
                        if let apiError = error as? APIError {
                            switch apiError {
                            case .unauthorized:
                                errorMessage = "Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın."
                                // Burada kullanıcıyı otomatik olarak login ekranına da yönlendirebilirsin.
                            default:
                                errorMessage = error.localizedDescription
                            }
                        } else {
                            errorMessage = "Lütfen internet bağlantınızı kontrol edin."
                        }
                AlertHelper.showAlert(viewController: self, title: "Hata", message: errorMessage, completion: {
                    // Bu kod bloğu, kullanıcı "Tamam" butonuna bastıktan
                    // sonra çalışacaktır.
                    print("Alert'in Tamam butonuna basıldı. Giriş ekranına yönlendiriliyor...")
                    self.logOutAndGoToLogin()})
                self.refreshController.endRefreshing()
            }
            
                
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 1. Doğru segue'yi tetiklediğimizden emin olalım.
        // Birden fazla segue olduğunda işi garantiye almak için.
        if segue.identifier == "showProjectDetail"{
            
            // 2. Gidilecek olan hedef View Controller'ı (ProjectDetailViewController) alalım.
            // 'segue.destination' hedefi verir, ama tipini bizim belirtmemiz gerekir.
            if let detailVC = segue.destination as? ProjectDetailViewController{
                // 3. 'sender' olarak gönderdiğimiz veriyi (projeyi) alalım.
                // 'sender' Any tipindedir, bu yüzden onu kendi modelimize (ProjectModel) dönüştürmemiz gerekir.
                
                if let projecttoSend = sender as? ProjectModel{
                    // 4. EN ÖNEMLİ ADIM: Veriyi, detay ekranının "posta kutusuna" koy
                    detailVC.project = projecttoSend
                }
            }
        }
    }
    
    @objc func refreshData(){
        print("Aşağı çekerek yenileme tetiklendi.")
        Task{
            await fetcUserProjects()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 1. Arama metni boş mu diye kontrol et.
        if searchText.isEmpty{
            // Eğer boşsa, filtrelenmiş listeyi orijinal listenin tamamıyla doldur.
            filteredProjects = projects
        }else{
            // Eğer boş değilse, 'allProjects' dizisini filtrele.
            filteredProjects = projects.filter{
                project in
                // Proje başlığı (küçük harfe çevrilmiş), arama metnini (küçük harfe çevrilmiş) içeriyor mu?
                return project.title.lowercased().contains(searchText.lowercased())
            }
        }
        
        // 2. TableView'e kendini yeni filtrelenmiş veriye göre güncellemesini söyle.
        tableView.reloadData()
        
    }
    
    func logOutAndGoToLogin(){
        KeyChainManager.shared.deleteToken()
                switchToMainApp()
    }
    
    func switchToMainApp() {
        DispatchQueue.main.async {
            guard let mainNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "toLoginPageNavigationController") else {
                print("Hata: toLoginPageNavigationController storyboard'da bulunamadı.")
                return
            }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate,
               let window = sceneDelegate.window {
                
                window.rootViewController = mainNavigationController
                UIView.transition(with: window,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: nil,
                                  completion: nil)
            }
        }
    }
}
