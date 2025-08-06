//
//  ProjectDetailViewController.swift
//  internShipProject
//
//  Created by Kerem Saltık on 31.07.2025.
//

import UIKit

protocol ProjectDetailDelegate: AnyObject {
    func projectWasUpdated()
}


class ProjectDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
  
    
    //MARK: - Variables
    // Bir önceki ekrandan (ProjectTableViewController) gelen projeyi tutacak olan değişken
    var project: ProjectModel?
    // Storyboard'dan gelen TableView'i buraya bağla
    @IBOutlet weak var tableView: UITableView!
    // TableView'in kullanacağı veri kaynağı dizisi
    var detailItems : [ProjectDetailModel] = []
    weak var delegate: ProjectDetailDelegate?
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // TableView'in yöneticisinin bu sınıf olduğunu belirtiyoruz
        tableView.dataSource = self
        tableView.delegate = self
        
        
        // Gelen proje verisini, tablonun anlayacağı formata dönüştürüyoruz
        prepareDataForTable()
        
        // (İsteğe bağlı) TableView'in altındaki boş hücre çizgilerini gizle
        tableView.tableFooterView = UIView()
        
        // --- HATA AYIKLAMA ---
           print("TableView'in frame'i: \(tableView.frame)")
           print("TableView'in alpha'sı: \(tableView.alpha)")
           print("TableView'in gizli mi: \(tableView.isHidden)")
           // --------------------
    }
    


    func prepareDataForTable(){
        print("--- prepareDataForTable ÇAĞRILDI ---")
        
        // Gelen projenin var olduğundan emin olalım
        guard let project = project else {
            print("HATA: 'project' değişkeni nil geldi. Veri aktarımı başarısız.")
            return }
        print("Proje başarıyla alındı: \(project.title)")
 
        
        // Ekranın başlığını proje adıyla güncelle
        self.title = project.title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long // Örn: "August 1, 2025"
        dateFormatter.locale = Locale(identifier: "tr_TR") // Türkçe format için
        
        let startDate = dateFormatter.string(from: project.startDate)
        let endDate = dateFormatter.string(from: project.endDate)
        
        // Proje verilerini, 'detailItems' dizisine ekleyelim.
        // Her bir eleman, tabloda yeni bir satır olacak.
        // İkon isimleri, Apple'ın SF Symbols kütüphanesinden alınmıştır.
        detailItems.append(ProjectDetailModel(label: "Açıklama", value: project.description, iconName: "text.alignleft"))
        detailItems.append(ProjectDetailModel(label: "Durum", value: project.status, iconName: "hourglass"))
        detailItems.append(ProjectDetailModel(label: "Başlangıç Tarihi", value: startDate, iconName: "calendar.badge.plus"))
        detailItems.append(ProjectDetailModel(label: "Bitiş Tarihi", value: endDate, iconName: "calendar.badge.minus"))
        detailItems.append(ProjectDetailModel(label: "İlgili E-posta", value: project.mail, iconName: "envelope.fill"))
        detailItems.append(ProjectDetailModel(label: "Proje Kategorisi", value: project.category ?? "", iconName: "tag.fill"))
        detailItems.append(ProjectDetailModel(label: "Proje Önem Derecesi", value: project.priority ?? "", iconName:"exclamationmark.circle.fill"))
        detailItems.append(ProjectDetailModel(label: "Proje Yetkilisi", value: project.projectManager ?? "", iconName: "person"))
        
        print("'detailItems' dizisi dolduruldu. Eleman sayısı: \(detailItems.count)")
        
        tableView.reloadData()
    }
    
    
    func formatDate(_ dateString: String) -> String{
        let formatter = ISO8601DateFormatter()
        // Milisaniyeleri de içeren formatı belirtelim
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString){
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long // Örn: "July 1, 2025"
            displayFormatter.timeStyle = .none
            displayFormatter.locale = Locale(identifier: "tr_TR") // Türkçe format için
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detailItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
        
        // O anki satır için doğru veriyi diziden al
        let item = detailItems[indexPath.row]
        
        // Hücreyi yapılandır (iOS 14+ için modern yöntem)
        var content = cell.defaultContentConfiguration()
        
        // Ana metin (Label)
        content.text = item.label
        content.textProperties.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // İkincil metin (Value)
        content.secondaryText = item.value
        content.secondaryTextProperties.color = .secondaryLabel
        
        // İkon
        if let iconName = item.iconName{
            content.image = UIImage(systemName: iconName)
        }
        
        // Açıklama hücresinin birden fazla satır göstermesini sağla
        if item.label == "Açıklama"{
            content.secondaryTextProperties.numberOfLines = 0
        }
        
        cell.contentConfiguration = content
        
        // Hücrenin seçilemez olmasını sağlar
        cell.selectionStyle = .none
        
        return cell
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("--- DETAY EKRANI 'prepare' FONKSİYONU ÇAĞRILDI ---")
           
           // 1. ADIM: Segue'nin kimliğini kontrol edelim.
           print("1. Tetiklenen Segue Identifier'ı: \(segue.identifier ?? "NIL - İSİM VERİLMEMİŞ!")")
           
           if segue.identifier == "editProjectSegue" {
               
               print("2. Segue identifier'ı doğru: 'editProjectSegue'")
               
               // 2. ADIM: Hedefin bir Navigation Controller olup olmadığını kontrol edelim.
               // Genellikle modal olarak açılan düzenleme ekranları bir Navigation Controller içinde olur.
               guard let navigationController = segue.destination as? UINavigationController else {
                   print("HATA: Hedef ekran bir UINavigationController değil! Storyboard'u kontrol et.")
                   return
               }
               
               print("3. Hedefin bir Navigation Controller olduğu doğrulandı.")
               
               // 3. ADIM: Navigation Controller'ın içindeki asıl View Controller'ı alalım.
               guard let editVC = navigationController.topViewController as? EditProjectTableViewController else {
                   print("HATA: Navigation Controller'ın içindeki ekran 'EditProjectTableViewController' değil! Storyboard'u kontrol et.")
                   return
               }
               
               print("4. Düzenleme ekranı (editVC) başarıyla bulundu.")
               
               // 4. ADIM: Gönderilecek verinin var olup olmadığını kontrol edelim.
               guard let projectData = self.project else {
                   print("HATA: Gönderilecek proje verisi (self.project) 'nil'!")
                   return
               }
               
               print("5. Gönderilecek proje başarıyla alındı: \(projectData.title)")
               
               // 5. ADIM: Veriyi, düzenleme ekranının "posta kutusuna" koyalım.
               editVC.projectToEdit = projectData
               
               print("6. Veri, editVC.projectToEdit değişkenine başarıyla atandı.")
               
           } else {
               print("UYARI: Farklı bir segue tetiklendi: \(segue.identifier ?? "Bilinmiyor")")
           }
    }
}
