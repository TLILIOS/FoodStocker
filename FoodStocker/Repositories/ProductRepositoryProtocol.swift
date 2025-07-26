import Foundation
import Combine

// MARK: - Product Repository Protocol
protocol ProductRepositoryProtocol {
    func fetchProducts() async throws -> [ProductModel]
    func addProduct(_ product: ProductModel) async throws
    func updateProduct(_ product: ProductModel) async throws
    func deleteProduct(withId id: UUID) async throws
    func searchProducts(query: String) async throws -> [ProductModel]
    func getProductsExpiringWithin(days: Int) async throws -> [ProductModel]
    func getExpiredProducts() async throws -> [ProductModel]
}

// MARK: - Sort Options
enum ProductSortOption: CaseIterable {
    case name
    case expirationDate
    case category
    case location
    case arrivalDate
    
    var displayName: String {
        switch self {
        case .name: return "Nom"
        case .expirationDate: return "Expiration"
        case .category: return "Catégorie"
        case .location: return "Emplacement"
        case .arrivalDate: return "Date d'arrivée"
        }
    }
    
    var icon: String {
        switch self {
        case .name: return "textformat.abc"
        case .expirationDate: return "calendar.badge.clock"
        case .category: return "folder.fill"
        case .location: return "location.fill"
        case .arrivalDate: return "calendar.badge.plus"
        }
    }
    
    func sort(_ products: [ProductModel]) -> [ProductModel] {
        switch self {
        case .name:
            return products.sorted { $0.name < $1.name }
        case .expirationDate:
            return products.sorted { $0.expirationDate < $1.expirationDate }
        case .category:
            return products.sorted { $0.category.rawValue < $1.category.rawValue }
        case .location:
            return products.sorted { $0.location.rawValue < $1.location.rawValue }
        case .arrivalDate:
            return products.sorted { $0.arrivalDate < $1.arrivalDate }
        }
    }
}