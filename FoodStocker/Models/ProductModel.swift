import Foundation
import SwiftUI

// MARK: - Product Domain Model
struct ProductModel: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let quantity: Double
    let unit: String
    let category: ProductCategory
    let location: ProductLocation
    let arrivalDate: Date
    let expirationDate: Date
    let lotNumber: String
    
    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: String,
        category: ProductCategory,
        location: ProductLocation,
        arrivalDate: Date,
        expirationDate: Date,
        lotNumber: String
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.location = location
        self.arrivalDate = arrivalDate
        self.expirationDate = expirationDate
        self.lotNumber = lotNumber
    }
}

// MARK: - Product Category
enum ProductCategory: String, CaseIterable, Codable {
    case fruits = "Fruits"
    case vegetables = "Légumes" 
    case dairy = "Produits laitiers"
    case meat = "Viandes"
    case fish = "Poissons"
    case canned = "Conserves"
    case beverages = "Boissons"
    case frozen = "Surgelés"
    case other = "Autres"
    
    var icon: String {
        switch self {
        case .fruits: return "leaf"
        case .vegetables: return "carrot"
        case .dairy: return "cup.and.saucer"
        case .meat: return "flame"
        case .fish: return "fish"
        case .canned: return "archivebox"
        case .beverages: return "cup.and.saucer"
        case .frozen: return "snowflake"
        case .other: return "tag"
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .fruits: return Color.CategoryColors.fruits
        case .vegetables: return Color.CategoryColors.vegetables
        case .dairy: return Color.CategoryColors.dairy
        case .meat: return Color.CategoryColors.meat
        case .fish, .canned, .beverages, .frozen, .other: return Color.CategoryColors.other
        }
    }
}

// MARK: - Product Location
enum ProductLocation: String, CaseIterable, Codable {
    case pantry = "Garde-manger"
    case refrigerator = "Réfrigérateur"
    case freezer = "Congélateur"
    case cupboard = "Placard"
    case other = "Autre"
    
    var icon: String {
        switch self {
        case .pantry: return "house"
        case .refrigerator: return "refrigerator"
        case .freezer: return "snowflake"
        case .cupboard: return "cabinet"
        case .other: return "questionmark.folder"
        }
    }
}

// MARK: - Expiration Status
enum ExpirationStatus: Equatable {
    case fresh
    case soonExpired(daysRemaining: Int)
    case expired(daysPast: Int)
    case unknown
    
    var color: Color {
        switch self {
        case .fresh: return .green
        case .soonExpired: return .orange
        case .expired: return .red
        case .unknown: return .gray
        }
    }
    
    var priority: Int {
        switch self {
        case .expired: return 0
        case .soonExpired: return 1
        case .fresh: return 2
        case .unknown: return 3
        }
    }
}

// MARK: - Product Extensions
extension ProductModel {
    var expirationStatus: ExpirationStatus {
        let calendar = Calendar.current
        let daysUntilExpiration = calendar.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        
        if daysUntilExpiration < 0 {
            return .expired(daysPast: abs(daysUntilExpiration))
        } else if daysUntilExpiration <= 3 {
            return .soonExpired(daysRemaining: daysUntilExpiration)
        } else {
            return .fresh
        }
    }
    
    var formattedQuantity: String {
        // Protection contre les valeurs NaN ou infinies
        let safeQuantity = quantity.isNaN || quantity.isInfinite ? 0.0 : quantity
        return String(format: "%.1f %@", safeQuantity, unit)
    }
    
    var isExpired: Bool {
        Date() > expirationDate
    }
    
    var isSoonExpired: Bool {
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        return daysUntilExpiration <= 3 && daysUntilExpiration >= 0
    }
}