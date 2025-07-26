import Foundation
import UserNotifications

// MARK: - User Notification Service Implementation
final class UserNotificationService: NotificationServiceProtocol {
    private let notificationCenter: UNUserNotificationCenter
    
    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
        setupNotificationCategories()
    }
    
    func requestPermission() async throws {
        let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
        
        if !granted {
            throw AppError.notificationError(.permissionDenied)
        }
    }
    
    func scheduleExpirationNotification(for product: ProductModel) async throws {
        // Remove existing notification for this product
        try await removeNotification(for: product.id)
        
        // Calculate notification date (24 hours before expiration)
        let notificationDate = Calendar.current.date(byAdding: .day, value: -1, to: product.expirationDate) ?? product.expirationDate
        
        // Don't schedule if date is in the past
        guard notificationDate > Date() else { return }
        
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: product.expirationDate).day ?? 0
        let content = NotificationContent(for: product, daysUntilExpiration: max(1, daysUntilExpiration))
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: content.identifier,
            content: createUNNotificationContent(from: content),
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            throw AppError.notificationError(.schedulingFailed)
        }
    }
    
    func removeNotification(for productId: UUID) async throws {
        let identifier = "expiration_\(productId.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    func removeAllNotifications() async throws {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Private Methods
    private func setupNotificationCategories() {
        let expirationCategory = UNNotificationCategory(
            identifier: "EXPIRATION_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([expirationCategory])
    }
    
    private func createUNNotificationContent(from content: NotificationContent) -> UNMutableNotificationContent {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.body
        notificationContent.categoryIdentifier = content.categoryIdentifier
        notificationContent.userInfo = content.userInfo
        notificationContent.sound = .default
        notificationContent.badge = 1
        
        return notificationContent
    }
}

// MARK: - Mock Notification Service for Testing
final class MockNotificationService: NotificationServiceProtocol {
    var permissionGranted = true
    var scheduledNotifications: [String] = []
    
    func requestPermission() async throws {
        if !permissionGranted {
            throw AppError.notificationError(.permissionDenied)
        }
    }
    
    func scheduleExpirationNotification(for product: ProductModel) async throws {
        let identifier = "expiration_\(product.id.uuidString)"
        scheduledNotifications.append(identifier)
    }
    
    func removeNotification(for productId: UUID) async throws {
        let identifier = "expiration_\(productId.uuidString)"
        scheduledNotifications.removeAll { $0 == identifier }
    }
    
    func removeAllNotifications() async throws {
        scheduledNotifications.removeAll()
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        return permissionGranted ? .authorized : .denied
    }
}