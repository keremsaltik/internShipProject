//
//  GenericResponse.swift
//  internShipProject
//
//  Created by Kerem Saltık on 4.08.2025.
//

import Foundation

// Bu struct, sunucudan gelen "İşlem başarılı oldu" veya "Bir hata oluştu"
// gibi genel amaçlı yanıtları karşılamak için kullanılır.
struct GenericResponse: Codable {
    let success: Bool
    let message: String? // Mesaj alanı bazen gelmeyebilir, o yüzden opsiyonel (?)
}
