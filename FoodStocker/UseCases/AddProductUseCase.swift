//
//  AddProductUseCase.swift
//  FoodStocker
//
//  Use Case pour l'ajout de produits avec validation complète
//

import Foundation
import os.log

// MARK: - Protocol
protocol AddProductUseCaseProtocol {
    func execute(_ product: ProductModel) async throws -> ProductModel
    func validateProduct(_ product: ProductModel) throws
}

// MARK: - Add Product Use Case
final class AddProductUseCase: AddProductUseCaseProtocol {
    
    // MARK: - Dependencies
    private let productRepository: ProductRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let logger: Logger
    
    // MARK: - Configuration
    private let notificationThresholdDays = 7
    
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
    
    func execute(_ product: ProductModel) async throws -> ProductModel {
        logger.debug("➕ Ajout produit: \(product.name)")
        
        // 1. Validation métier
        try validateProduct(product)
        
        // 2. Vérifier si produit existe déjà (par nom + lot)
        try await checkForDuplicates(product)
        
        // 3. Ajouter au repository
        try await productRepository.addProduct(product)
        
        // 4. Programmer notification si nécessaire
        try await scheduleNotificationIfNeeded(for: product)
        
        logger.info("✅ Produit ajouté avec succès: \(product.name)")
        
        return product
    }
    
    func validateProduct(_ product: ProductModel) throws {
        logger.debug("🔍 Validation produit: \(product.name)")
        
        // Validation nom
        guard !product.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AppError.validationError(.emptyName)
        }
        
        // Validation quantité
        guard product.quantity > 0 else {
            throw AppError.validationError(.invalidQuantity)
        }
        
        // Validation date expiration
        guard product.expirationDate > Date() else {
            throw AppError.validationError(.pastExpirationDate)
        }
        
        // Validation numéro de lot
        guard !product.lotNumber.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AppError.validationError(.emptyLotNumber)
        }
        
        // Validation cohérence dates
        guard product.expirationDate > product.arrivalDate else {
            throw AppError.validationError(.pastExpirationDate)
        }
        
        logger.debug("✅ Validation produit réussie")
    }
    
    // MARK: - Private Methods
    
    private func checkForDuplicates(_ product: ProductModel) async throws {
        let existingProducts = try await productRepository.fetchProducts()
        
        let duplicate = existingProducts.first { existing in
            existing.name.lowercased() == product.name.lowercased() &&
            existing.lotNumber == product.lotNumber
        }
        
        if let duplicate = duplicate {
            logger.warning("⚠️ Produit en doublon détecté: \(duplicate.name) - \(duplicate.lotNumber)")
            // Optionnel: Lancer une erreur ou fusionner les quantités
            // throw AppError.validationError(.duplicateProduct)
        }
    }
    
    private func scheduleNotificationIfNeeded(for product: ProductModel) async throws {
        let daysUntilExpiration = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: product.expirationDate
        ).day ?? 0
        
        if daysUntilExpiration <= notificationThresholdDays && daysUntilExpiration >= 0 {
            try await notificationService.scheduleExpirationNotification(for: product)
            logger.info("🔔 Notification programmée pour \(product.name) (expire dans \(daysUntilExpiration) jours)")
        }
    }
}

// MARK: - Mock Implementation
final class MockAddProductUseCase: AddProductUseCaseProtocol {
    var shouldThrowError = false
    var shouldThrowValidationError = false
    var addedProducts: [ProductModel] = []
    
    func execute(_ product: ProductModel) async throws -> ProductModel {
        if shouldThrowError {
            throw AppError.dataError(.saveFailed)
        }
        if shouldThrowValidationError {
            throw AppError.validationError(.emptyName)
        }
        
        addedProducts.append(product)
        return product
    }
    
    func validateProduct(_ product: ProductModel) throws {
        if shouldThrowValidationError {
            throw AppError.validationError(.emptyName)
        }
    }
}