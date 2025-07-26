import Foundation
import UserNotifications

// MARK: - Notification Service Protocol
protocol NotificationServiceProtocol {
    func requestPermission() async throws
    func scheduleExpirationNotification(for product: ProductModel) async throws
    func removeNotification(for productId: UUID) async throws
    func removeAllNotifications() async throws
    func checkPermissionStatus() async -> UNAuthorizationStatus
}

// MARK: - Notification Content
struct NotificationContent {
    let title: String
    let body: String
    let identifier: String
    let categoryIdentifier: String
    let userInfo: [String: Any]
    
    init(for product: ProductModel, daysUntilExpiration: Int) {
        self.identifier = "expiration_\(product.id.uuidString)"
        self.categoryIdentifier = "EXPIRATION_REMINDER"
        
        if daysUntilExpiration <= 0 {
            self.title = "⚠️ Produit expiré"
            self.body = "\(product.name) a expiré. Vérifiez sa qualité avant consommation."
        } else {
            self.title = "🔔 Expiration proche"
            self.body = "\(product.name) expire dans \(daysUntilExpiration) jour\(daysUntilExpiration > 1 ? "s" : "")"
        }
        
        self.userInfo = [
            "productId": product.id.uuidString,
            "productName": product.name,
            "expirationDate": product.expirationDate.timeIntervalSince1970
        ]
    }
}