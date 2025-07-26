//
//  UpdateProductUseCase.swift
//  FoodStocker
//
//  Use Case pour la mise à jour de produits avec gestion des notifications
//

import Foundation
import os.log

// MARK: - Protocol
protocol UpdateProductUseCaseProtocol {
    func execute(_ product: ProductModel) async throws -> ProductModel
    func updateExpirationDate(productId: UUID, newDate: Date) async throws -> ProductModel
    func updateQuantity(productId: UUID, newQuantity: Double) async throws -> ProductModel
}

// MARK: - Update Product Use Case
final class UpdateProductUseCase: UpdateProductUseCaseProtocol {
    
    // MARK: - Dependencies
    private let productRepository: ProductRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let addProductUseCase: AddProductUseCaseProtocol
    private let logger: Logger
    
    // MARK: - Configuration
    private let notificationThresholdDays = 7
    
    // MARK: - Initialization
    init(
        productRepository: ProductRepositoryProtocol,
        notificationService: NotificationServiceProtocol,
        addProductUseCase: AddProductUseCaseProtocol
    ) {
        self.productRepository = productRepository
        self.notificationService = notificationService
        self.addProductUseCase = addProductUseCase
        self.logger = FoodStockerLogger.log(.viewModel)
    }
    
    // MARK: - Business Logic
    
    func execute(_ product: ProductModel) async throws -> ProductModel {
        logger.debug("✏️ Mise à jour produit: \(product.name)")
        
        // 1. Validation avec les mêmes règles que l'ajout
        try addProductUseCase.validateProduct(product)
        
        // 2. Vérifier que le produit existe
        let existingProducts = try await productRepository.fetchProducts()
        guard existingProducts.contains(where: { $0.id == product.id }) else {
            throw AppError.dataError(.productNotFound)
        }
        
        // 3. Mettre à jour dans le repository
        try await productRepository.updateProduct(product)
        
        // 4. Mettre à jour les notifications
        try await updateNotificationsIfNeeded(for: product)
        
        logger.info("✅ Produit mis à jour: \(product.name)")
        
        return product
    }
    
    func updateExpirationDate(productId: UUID, newDate: Date) async throws -> ProductModel {
        logger.debug("📅 Mise à jour date d'expiration pour: \(productId)")
        
        // Validation de la nouvelle date
        guard newDate > Date() else {
            throw AppError.validationError(.pastExpirationDate)
        }
        
        // Récupérer le produit existant
        let existingProducts = try await productRepository.fetchProducts()
        guard let product = existingProducts.first(where: { $0.id == productId }) else {
            throw AppError.dataError(.productNotFound)
        }
        
        // Créer une copie avec la nouvelle date
        let updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            quantity: product.quantity,
            unit: product.unit,
            category: product.category,
            location: product.location,
            arrivalDate: product.arrivalDate,
            expirationDate: newDate,
            lotNumber: product.lotNumber
        )
        
        return try await execute(updatedProduct)
    }
    
    func updateQuantity(productId: UUID, newQuantity: Double) async throws -> ProductModel {
        logger.debug("🔢 Mise à jour quantité pour: \(productId)")
        
        // Validation de la nouvelle quantité
        guard newQuantity > 0 else {
            throw AppError.validationError(.invalidQuantity)
        }
        
        // Récupérer le produit existant
        let existingProducts = try await productRepository.fetchProducts()
        guard let product = existingProducts.first(where: { $0.id == productId }) else {
            throw AppError.dataError(.productNotFound)
        }
        
        // Créer une copie avec la nouvelle quantité
        let updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            quantity: newQuantity,
            unit: product.unit,
            category: product.category,
            location: product.location,
            arrivalDate: product.arrivalDate,
            expirationDate: product.expirationDate,
            lotNumber: product.lotNumber
        )
        
        return try await execute(updatedProduct)
    }
    
    // MARK: - Private Methods
    
    private func updateNotificationsIfNeeded(for product: ProductModel) async throws {
        // Supprimer l'ancienne notification
        try await notificationService.removeNotification(for: product.id)
        
        // Reprogrammer si nécessaire
        let daysUntilExpiration = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: product.expirationDate
        ).day ?? 0
        
        if daysUntilExpiration <= notificationThresholdDays && daysUntilExpiration >= 0 {
            try await notificationService.scheduleExpirationNotification(for: product)
            logger.info("🔔 Notification reprogrammée pour \(product.name)")
        } else {
            logger.debug("🔕 Pas de notification nécessaire pour \(product.name)")
        }
    }
}

// MARK: - Mock Implementation
final class MockUpdateProductUseCase: UpdateProductUseCaseProtocol {
    var shouldThrowError = false
    var shouldThrowNotFoundError = false
    var shouldThrowValidationError = false
    var updatedProducts: [ProductModel] = []
    
    func execute(_ product: ProductModel) async throws -> ProductModel {
        if shouldThrowError {
            throw AppError.dataError(.saveFailed)
        }
        if shouldThrowNotFoundError {
            throw AppError.dataError(.productNotFound)
        }
        if shouldThrowValidationError {
            throw AppError.validationError(.emptyName)
        }
        
        updatedProducts.append(product)
        return product
    }
    
    func updateExpirationDate(productId: UUID, newDate: Date) async throws -> ProductModel {
        if shouldThrowError {
            throw AppError.dataError(.saveFailed)
        }
        
        let mockProduct = ProductModel(
            id: productId,
            name: "Mock Product",
            quantity: 1.0,
            unit: "kg",
            category: .fruits,
            location: .refrigerator,
            arrivalDate: Date(),
            expirationDate: newDate,
            lotNumber: "MOCK123"
        )
        
        updatedProducts.append(mockProduct)
        return mockProduct
    }
    
    func updateQuantity(productId: UUID, newQuantity: Double) async throws -> ProductModel {
        if shouldThrowError {
            throw AppError.dataError(.saveFailed)
        }
        
        let mockProduct = ProductModel(
            id: productId,
            name: "Mock Product",
            quantity: newQuantity,
            unit: "kg",
            category: .fruits,
            location: .refrigerator,
            arrivalDate: Date(),
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            lotNumber: "MOCK123"
        )
        
        updatedProducts.append(mockProduct)
        return mockProduct
    }
}