//
//  ManageExpirationAlertsUseCase.swift
//  FoodStocker
//
//  Use Case pour la gestion des alertes d'expiration
//

import Foundation
import os.log

// MARK: - Alerts Result Model
struct ExpirationAlertsResult {
    let expiredProducts: [ProductModel]
    let soonExpiredProducts: [ProductModel]
    let totalCount: Int
    
    var hasAlerts: Bool {
        totalCount > 0
    }
    
    init(expired: [ProductModel], soonExpired: [ProductModel]) {
        self.expiredProducts = expired
        self.soonExpiredProducts = soonExpired
        self.totalCount = expired.count + soonExpired.count
    }
}

// MARK: - Protocol
protocol ManageExpirationAlertsUseCaseProtocol {
    func loadAlerts() async throws -> ExpirationAlertsResult
    func scheduleNotificationsForUpcomingProducts(_ products: [ProductModel]) async throws
    func dismissAlert(for product: ProductModel) async throws
}

// MARK: - Manage Expiration Alerts Use Case
final class ManageExpirationAlertsUseCase: ManageExpirationAlertsUseCaseProtocol {
    
    // MARK: - Dependencies
    private let productRepository: ProductRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let logger: Logger
    
    // MARK: - Configuration
    private let soonExpiredThresholdDays = 3
    private let notificationSchedulingThresholdDays = 7
    
    // MARK: - Initialization
    init(
        productRepository: ProductRepositoryProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.productRepository = productRepository
        self.notificationService = notificationService
        self.logger = FoodStockerLogger.log(.viewModel)
    }
    
    // MARK: - Business Logic
    
    func loadAlerts() async throws -> ExpirationAlertsResult {
        logger.debug("📋 Chargement alertes d'expiration")
        
        // Chargement concurrent des deux types d'alertes
        async let expiredTask = productRepository.getExpiredProducts()
        async let soonExpiredTask = productRepository.getProductsExpiringWithin(days: soonExpiredThresholdDays)
        
        let expiredProducts = try await expiredTask
        let soonExpiredProducts = try await soonExpiredTask
        
        let result = ExpirationAlertsResult(
            expired: expiredProducts,
            soonExpired: soonExpiredProducts
        )
        
        logger.info("✅ Alertes chargées - Expirés: \(result.expiredProducts.count), Bientôt: \(result.soonExpiredProducts.count)")
        
        return result
    }
    
    func scheduleNotificationsForUpcomingProducts(_ products: [ProductModel]) async throws {
        logger.debug("🔔 Programmation notifications pour \(products.count) produits")
        
        let upcomingProducts = products.filter { product in
            let daysUntilExpiration = Calendar.current.dateComponents(
                [.day],
                from: Date(),
                to: product.expirationDate
            ).day ?? 0
            
            return daysUntilExpiration <= notificationSchedulingThresholdDays && daysUntilExpiration >= 0
        }
        
        // Programmation concurrente des notifications
        try await withThrowingTaskGroup(of: Void.self) { group in
            for product in upcomingProducts {
                group.addTask { [weak self] in
                    try await self?.notificationService.scheduleExpirationNotification(for: product)
                }
            }
            
            // Attendre que toutes les notifications soient programmées
            try await group.waitForAll()
        }
        
        logger.info("✅ \(upcomingProducts.count) notifications programmées")
    }
    
    func dismissAlert(for product: ProductModel) async throws {
        logger.debug("🔕 Suppression alerte pour: \(product.name)")
        
        // Supprimer la notification associée
        try await notificationService.removeNotification(for: product.id)
        
        logger.info("✅ Alerte supprimée pour: \(product.name)")
    }
    
    // MARK: - Helper Methods
    
    /// Analyse des tendances d'expiration (future fonctionnalité)
    func analyzeExpirationTrends(_ products: [ProductModel]) -> ExpirationTrendsAnalysis {
        let calendar = Calendar.current
        let now = Date()
        
        var categoryExpiration: [ProductCategory: Int] = [:]
        var locationExpiration: [ProductLocation: Int] = [:]
        
        for product in products {
            let daysUntilExpiration = calendar.dateComponents([.day], from: now, to: product.expirationDate).day ?? 0
            
            if daysUntilExpiration <= 7 {
                categoryExpiration[product.category, default: 0] += 1
                locationExpiration[product.location, default: 0] += 1
            }
        }
        
        return ExpirationTrendsAnalysis(
            categoriesAtRisk: categoryExpiration,
            locationsAtRisk: locationExpiration
        )
    }
}

// MARK: - Expiration Trends Analysis
struct ExpirationTrendsAnalysis {
    let categoriesAtRisk: [ProductCategory: Int]
    let locationsAtRisk: [ProductLocation: Int]
    
    var mostAtRiskCategory: ProductCategory? {
        categoriesAtRisk.max { $0.value < $1.value }?.key
    }
    
    var mostAtRiskLocation: ProductLocation? {
        locationsAtRisk.max { $0.value < $1.value }?.key
    }
}

// MARK: - Mock Implementation
final class MockManageExpirationAlertsUseCase: ManageExpirationAlertsUseCaseProtocol {
    var shouldThrowError = false
    var mockExpiredProducts: [ProductModel] = []
    var mockSoonExpiredProducts: [ProductModel] = []
    var dismissedProducts: [ProductModel] = []
    
    func loadAlerts() async throws -> ExpirationAlertsResult {
        if shouldThrowError {
            throw AppError.dataError(.fetchFailed)
        }
        
        return ExpirationAlertsResult(
            expired: mockExpiredProducts,
            soonExpired: mockSoonExpiredProducts
        )
    }
    
    func scheduleNotificationsForUpcomingProducts(_ products: [ProductModel]) async throws {
        if shouldThrowError {
            throw AppError.notificationError(.schedulingFailed)
        }
    }
    
    func dismissAlert(for product: ProductModel) async throws {
        if shouldThrowError {
            throw AppError.notificationError(.schedulingFailed)
        }
        
        dismissedProducts.append(product)
    }
}