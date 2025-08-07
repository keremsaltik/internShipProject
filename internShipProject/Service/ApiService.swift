//
//  Service.swift
//  internShipProject
//
//  Created by Kerem Saltık on 23.07.2025.
//

// APIService.swift

import Foundation

enum APIError: Error,LocalizedError{
    case unauthorized(message: String) // 401: Token geçersiz veya şifre yanlış
    case serverError(message: String) // 409: E-posta zaten kullanımda
    case decodingError // 5xx: Sunucu tarafı hatası
    case urlError // Gelen JSON veri formatı bozuk
    case conflict(message: String) // Programatik olarak URL oluşturulamadı
    
    // Bu kısım, her bir hata tipi için kullanıcıya gösterilecek standart bir metin sağlar.
    var errorDescription: String?{
        switch self{
        case .unauthorized(let message):
            return message
        case .serverError(let message):
            return message
        case .conflict(let message):
            return message
        case .decodingError:
            return "Sunucudan gelen yanıt anlaşılamadı. Lütfen daha sonra tekrar deneyin."
        case .urlError:
            return "Uygulama, geçersiz bir sunucu adresine bağlanmaya çalıştı."
        }
    }
}

class APIService {
    
   
    
    // Bu servis sınıfına projenin her yerinden kolayca erişmek için Singleton yapısı
    static let shared = APIService()
    private init() {}
    
    // Giriş isteğini yapan asenkron fonksiyon
    func login(requestData: LoginRequest) async throws -> LoginResponse {
        
        // 1. Node-RED API'nizin adresi
        let urlString = "\(NetworkInfo.Hosts.localHost)/login" // <-- Kendi IP adresiimiz.
        
        guard let url = URL(string: urlString) else {
            throw APIError.urlError // Geçersiz URL hatası fırlat
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
            throw APIError.serverError(message: "Geçersiz Sunucu Yanıtı") // Sunucu hatası fırlat
        }
        
        // 5. Gelen JSON verisini LoginResponse modeline dönüştür ve geri döndür
        let loginResponse = try? JSONDecoder().decode(LoginResponse.self, from: data)
        
        // Durum koduna göre karar verelim.
               switch httpResponse.statusCode {
               case 200:
                   // Başarılı!
                   if let response = loginResponse {
                       return response
                   } else {
                       // 200 OK geldi ama veri çözülemedi, bu garip bir durum.
                       throw APIError.decodingError
                   }
               case 401, 404: // 401 Unauthorized veya 404 Not Found (Kullanıcı bulunamadı)
                   // Başarısız giriş. Sunucudan gelen hata mesajını kullanalım.
                   let message = loginResponse?.message ?? "E-posta veya şifre hatalı."
                   throw APIError.unauthorized(message: message)
               default:
                   // Diğer tüm sunucu hataları.
                   let message = loginResponse?.message ?? "Sunucuda bilinmeyen bir hata oluştu."
                   throw APIError.serverError(message: message)
               }
        
    }
    
    func register(requestData: RegisterRequest) async throws -> RegisterResponse{
        // Api
        let urlString = "\(NetworkInfo.Hosts.localHost)/createUser" // Sunucu adresi
        
        guard let url = URL(string: urlString) else{
            throw APIError.urlError
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
            throw APIError.serverError(message: "Geçersiz sunucu yanıtı") //Sunucu hatası
        }
        
        // Gelen JSON verisini RegisterResponse modeline dönüştür ve geri döndür.
        let registerResponse = try? JSONDecoder().decode(RegisterResponse.self, from: data)
        switch httpResponse.statusCode {
           case 201: // Created
            if let response = registerResponse {
                   return response
               } else {
                   throw APIError.decodingError
               }
           case 409: // Conflict (E-posta zaten var)
            let message = registerResponse?.message ?? "Bu e-posta adresi zaten kullanılıyor."
               throw APIError.conflict(message: message)
           default:
            let message = registerResponse?.message ?? "Sunucuda bilinmeyen bir hata oluştu."
               throw APIError.serverError(message: message)
           }
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
    
    // APIService.swift içindeki fetchProjects fonksiyonu
    
    func fetchProjects() async throws -> [ProjectModel] {
        
        let urlString = "\(NetworkInfo.Hosts.localHost)/project"
        // ---------------------------------------------------------
        
        print("NİHAİ TEST: İstek atılacak URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("HATA: Elle yazılan URL geçersiz!")
            throw URLError(.badURL)
        }
        
        guard let token = KeyChainManager.shared.getToken() else {
            print("HATA: Keychain'den token okunamadı!")
            throw URLError(.userAuthenticationRequired)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("NİHAİ TEST: İstek şimdi gönderilecek...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("HATA: Sunucudan başarılı olmayan bir durum kodu alındı: \(statusCode)")
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            
            //Tarih verilerini belirli bir formatta ekranda gösterebilmek için DateFormatter() kullanıyoruz.
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let projects = try decoder.decode([ProjectModel].self, from: data)
            
            print("BAŞARILI! Projeler başarıyla çözümlendi. Bulunan proje sayısı: \(projects.count)")
            return projects
            
        } catch {
            print("HATA YAKALANDI: \(error.localizedDescription)")
            throw error
        }
    }
    
    func createProject(projectData: CreateProjectRequest) async throws -> ProjectResponse{
        // 1. URL'i oluştur
        let urlString = "\(NetworkInfo.Hosts.localHost)/createProject"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // 2. Keychain'den token'ı al
        guard let token = KeyChainManager.shared.getToken() else {
            print("Token alınamadı!")
            return ProjectResponse(success: false, message: "Token yok")
        }
        
        // 3. POST isteğini oluştur ve başlıkları ekle
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // 4. Proje verisini JSON'a çevirip isteğin gövdesine ekle
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(projectData)
        
        //request.httpBody = try JSONEncoder().encode(projectData)
        
        // 5. API isteğini yap ve yanıtı bekle
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 6. Yanıtın durum kodunu kontrol et (201 Created bekliyoruz)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        
        // 7. Gelen yanıtı GenericResponse modeline dönüştür
        let genericResponse = try JSONDecoder().decode(ProjectResponse.self, from: data)
        return genericResponse
    }
    
    func deleteProject(projectTitle: String) async throws{
        print("--- PROJE SİLME TESTİ BAŞLADI ---")
            
            // 1. ADIM: URL'i kontrol et
            let urlString = "\(NetworkInfo.Hosts.localHost)/delProject"
            print("1. İstek atılacak URL: \(urlString)")
            guard let url = URL(string: urlString) else {
                print("HATA: URL geçersiz! (URL'i veya projectId'yi kontrol et)")
                throw URLError(.badURL)
            }
            
            // 2. ADIM: Token'ı kontrol et
            print("2. Keychain'den token okunuyor...")
            guard let token = KeyChainManager.shared.getToken() else {
                print("HATA: Keychain'den token okunamadı (nil)! (Kullanıcı giriş yapmış mı?)")
                throw URLError(.userAuthenticationRequired)
            }
            print("3. Token başarıyla okundu.")
            
            // 3. ADIM: İsteği ve başlığı kontrol et
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(["title": projectTitle])
            print("4. İstek metodu 'DELETE' ve başlık (header) ayarlandı.")
            
            // 4. ADIM: Ağ isteğini göndermeden hemen önce
            print("5. API isteği şimdi gönderilecek...")
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                print("6. Sunucudan yanıt alındı.")
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("HATA: Sunucudan gelen yanıt HTTP formatında değil.")
                    throw URLError(.badServerResponse)
                }
                
                print("7. Sunucudan gelen HTTP durum kodu: \(httpResponse.statusCode)")
                
                // Sunucudan gelen durum kodunu kontrol et (200 veya 204 bekliyoruz)
                guard (httpResponse.statusCode == 200 || httpResponse.statusCode == 204) else {
                    print("HATA: Sunucudan başarılı olmayan bir durum kodu alındı.")
                    // 401 (Unauthorized) hatası, token'ın geçersiz veya süresinin dolmuş olduğu anlamına gelir.
                    if httpResponse.statusCode == 401 {
                        throw URLError(.userAuthenticationRequired)
                    }
                    throw URLError(.badServerResponse)
                }
                
                print("--- PROJE SİLME TESTİ BAŞARILI ---")
                // Başarılı olduğu için bir şey return etmiyoruz.
                
            } catch {
                // Eğer yukarıdaki adımlardan herhangi birinde hata olursa, bu blok çalışır.
                print("HATA YAKALANDI: \(error)")
                print("Hatanın açıklaması: \(error.localizedDescription)")
                throw error // Hatayı bir üst katmana fırlat
            }
    }
    
    func fetchAllUsers() async throws -> [UserViewModel]{
        let urlString = "\(NetworkInfo.Hosts.localHost)/users/list"
        guard let url = URL(string: urlString) else{
            throw URLError(.badURL)
        }
        
        guard let token = KeyChainManager.shared.getToken() else{
            print("HATA: Keychain'den token okunamadı (nil)! (Kullanıcı giriş yapmış mı?)")
            throw URLError(.userAuthenticationRequired)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponses = response as? HTTPURLResponse, httpResponses.statusCode == 200 else{
            throw URLError(.badServerResponse)
        }
        
        let users = try JSONDecoder().decode([UserViewModel].self, from: data)
        return users
    }
    
    func fetchCategories() async throws -> [CategoryModel]{
        let urlString = "\(NetworkInfo.Hosts.localHost)/categories"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
            
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponses = response as? HTTPURLResponse, httpResponses.statusCode == 200 else{
            throw URLError(.badServerResponse)
        }
        
        let categories = try JSONDecoder().decode([CategoryModel].self, from: data)
        return categories
    }
    
    func updateProject(projectData: ProjectModel) async throws -> GenericResponse {
        let urlString = "\(NetworkInfo.Hosts.localHost)/updateOneproject"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        guard let token = KeyChainManager.shared.getToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Tarihler zaten String olduğu için, standart Encoder yeterli.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(projectData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpresponse = response as? HTTPURLResponse, httpresponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // 'let genericResponse' satırındaki 'try' eksikti, onu da ekleyelim.
        let genericResponse = try JSONDecoder().decode(GenericResponse.self, from: data)
        return genericResponse
    }
    
}
