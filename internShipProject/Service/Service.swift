//
//  Service.swift
//  internShipProject
//
//  Created by Kerem Saltık on 23.07.2025.
//

// APIService.swift

import Foundation

class APIService {
    
    // Bu servis sınıfına projenin her yerinden kolayca erişmek için Singleton yapısı
    static let shared = APIService()
    private init() {}

    // Giriş isteğini yapan asenkron fonksiyon
    func login(requestData: LoginRequest) async throws -> LoginResponse {
        
        // 1. Node-RED API'nizin adresi
        let urlString = "\(NetworkInfo.Hosts.localHost)/login" // <-- Kendi IP adresiimiz.
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL) // Geçersiz URL hatası fırlat
        }
        
        // 2. HTTP POST isteğini oluştur
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Gönderdiğimiz verinin JSON formatında olduğunu belirtiyoruz
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // LoginRequest nesnesini JSON verisine çevirip isteğin gövdesine (body) ekliyoruz
        request.httpBody = try JSONEncoder().encode(requestData)
        
        // 3. API isteğini yap ve yanıtı bekle
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. Yanıtın başarılı olup olmadığını kontrol et (örn: HTTP 200 OK)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse) // Sunucu hatası fırlat
        }
        
        // 5. Gelen JSON verisini LoginResponse modeline dönüştür ve geri döndür
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        return loginResponse
    }
    
    func register(requestData: RegisterRequest) async throws -> RegisterResponse{
        // Api
        let urlString = "\(NetworkInfo.Hosts.localHost)/createUser" // Sunucu adresi
        
        guard let url = URL(string: urlString) else{
            throw URLError(.badURL)
        }
        
        // İstek oluşturma
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // JSON formatında verileri gönderiyoruz.
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // RegisterRequest nesnesini JSON verisine çevirip isteğin gövdesine ekliyoruz.
        request.httpBody = try JSONEncoder().encode(requestData)
        
        // Api isteği ve yanıt bekleme
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Yanıtın başarılı olup olmadığı ile ilgili kontrol
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else{
            throw URLError(.badServerResponse) //Sunucu hatası
        }
        
        // Gelen JSON verisini RegisterResponse modeline dönüştür ve geri döndür.
        let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
        return registerResponse
    }
    
    
    func fetchProfile(completion: @escaping (Result<ProfileResponse, Error>) -> Void){
        // Önce token'ı alalım.
        guard let token = KeyChainManager.shared.getToken() else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token not found. Please login."])))
            return }
        
        guard let url = URL(string: "\(NetworkInfo.Hosts.localHost)/profile") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 2. En önemli kısım: Authorization başlığını ekle
        // Format: "Bearer <token>"
        request.setValue("Bearer \(token) ", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) {data, response, error in
            if let error = error{
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                // Token geçersiz veya süresi dolmuş. Kullanıcıyı tekrar login ekranına yönlendir.
                completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])))
                           return
            }
            
            guard let data = data else { return }
            
            do {
                let profile = try JSONDecoder().decode(ProfileResponse.self, from: data)
                completion(.success(profile))
            }catch{
                completion(.failure(error))
            }
        }.resume()
    }
}
