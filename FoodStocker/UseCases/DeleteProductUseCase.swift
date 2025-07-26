//
//  DeleteProductUseCase.swift
//  FoodStocker
//
//  Use Case pour la suppression de produits avec nettoyage des notifications
//

import Foundation
import os.log

// MARK: - Protocol
protocol DeleteProductUseCaseProtocol {
    func execute(productId: UUID) async throws
    func executeWithProduct(_ product: ProductModel) async throws
}

// MARK: - Delete Product Use Case
final class DeleteProductUseCase: DeleteProductUseCaseProtocol {
    
    // MARK: - Dependencies
    private let productRepository: ProductRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let logger: Logger
    
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
    
    func execute(productId: UUID) async throws {
        logger.debug("🗑️ Suppression produit ID: \(productId)")
        
        // 1. Vérifier que le produit existe
        let existingProducts = try await productRepository.fetchProducts()
        guard let product = existingProducts.first(where: { $0.id == productId }) else {
            throw AppError.dataError(.productNotFound)
        }
        
        // 2. Supprimer du repository
        try await productRepository.deleteProduct(withId: productId)
        
        // 3. Supprimer les notifications associées
        try await notificationService.removeNotification(for: productId)
        
        logger.info("✅ Produit supprimé: \(product.name)")
    }
    
    func executeWithProduct(_ product: ProductModel) async throws {
        logger.debug("🗑️ Suppression produit: \(product.name)")
        
        // 1. Supprimer du repository
        try await productRepository.deleteProduct(withId: product.id)
        
        // 2. Supprimer les notifications associées
        try await notificationService.removeNotification(for: product.id)
        
        logger.info("✅ Produit supprimé: \(product.name)")
    }
}

// MARK: - Mock Implementation
final class MockDeleteProductUseCase: DeleteProductUseCaseProtocol {
    var shouldThrowError = false
    var shouldThrowNotFoundError = false
    var deletedProductIds: [UUID] = []
    
    func execute(productId: UUID) async throws {
        if shouldThrowError {
            throw AppError.dataError(.deleteFailed)
        }
        if shouldThrowNotFoundError {
            throw AppError.dataError(.productNotFound)
        }
        
        deletedProductIds.append(productId)
    }
    
    func executeWithProduct(_ product: ProductModel) async throws {
        if shouldThrowError {
            throw AppError.dataError(.deleteFailed)
        }
        
        deletedProductIds.append(product.id)
    }
}