//
//  SearchProductsUseCase.swift
//  FoodStocker
//
//  Use Case pour la recherche et le tri des produits
//

import Foundation
import os.log

// MARK: - Protocol
protocol SearchProductsUseCaseProtocol {
    func fetchAllProducts() async throws -> [ProductModel]
    
    func searchProducts(
        query: String,
        sortOption: ProductSortOption
    ) async throws -> [ProductModel]
    
    func execute(
        query: String,
        allProducts: [ProductModel],
        sortOption: ProductSortOption
    ) async throws -> [ProductModel]
    
    func executeWithRepository(
        query: String,
        sortOption: ProductSortOption
    ) async throws -> [ProductModel]
}

// MARK: - Search Products Use Case
final class SearchProductsUseCase: SearchProductsUseCaseProtocol {
    
    // MARK: - Dependencies
    private let productRepository: ProductRepositoryProtocol
    private let logger: Logger
    
    // MARK: - Initialization
    init(productRepository: ProductRepositoryProtocol) {
        self.productRepository = productRepository
        self.logger = FoodStockerLogger.log(.viewModel)
    }
    
    // MARK: - Business Logic
    
    func fetchAllProducts() async throws -> [ProductModel] {
        logger.debug("📋 Récupération de tous les produits")
        return try await productRepository.fetchProducts()
    }
    
    func searchProducts(
        query: String,
        sortOption: ProductSortOption
    ) async throws -> [ProductModel] {
        return try await executeWithRepository(query: query, sortOption: sortOption)
    }
    
    /// Recherche dans une liste existante (pour éviter les appels réseau)
    func execute(
        query: String,
        allProducts: [ProductModel],
        sortOption: ProductSortOption
    ) async throws -> [ProductModel] {
        
        logger.debug("🔍 Recherche locale: '\(query)' dans \(allProducts.count) produits")
        
        let filteredProducts: [ProductModel]
        
        if query.isEmpty {
            filteredProducts = allProducts
        } else {
            // Recherche insensible à la casse dans nom, catégorie, emplacement
            let lowercaseQuery = query.lowercased()
            
            filteredProducts = allProducts.filter { product in
                product.name.lowercased().contains(lowercaseQuery) ||
                product.category.rawValue.lowercased().contains(lowercaseQuery) ||
                product.location.rawValue.lowercased().contains(lowercaseQuery) ||
                product.lotNumber.lowercased().contains(lowercaseQuery)
            }
        }
        
        // Appliquer le tri
        let sortedProducts = sortOption.sort(filteredProducts)
        
        logger.info("✅ Recherche terminée: \(sortedProducts.count) résultats pour '\(query)'")
        
        return sortedProducts
    }
    
    /// Recherche avec appel au repository (pour recherche avancée)
    func executeWithRepository(
        query: String,
        sortOption: ProductSortOption
    ) async throws -> [ProductModel] {
        
        logger.debug("🔍 Recherche repository: '\(query)'")
        
        let searchResults: [ProductModel]
        
        if query.isEmpty {
            searchResults = try await productRepository.fetchProducts()
        } else {
            searchResults = try await productRepository.searchProducts(query: query)
        }
        
        // Appliquer le tri
        let sortedProducts = sortOption.sort(searchResults)
        
        logger.info("✅ Recherche repository terminée: \(sortedProducts.count) résultats")
        
        return sortedProducts
    }
}

// MARK: - Mock Implementation
final class MockSearchProductsUseCase: SearchProductsUseCaseProtocol {
    var shouldThrowError = false
    var mockResults: [ProductModel] = []
    
    func fetchAllProducts() async throws -> [ProductModel] {
        if shouldThrowError {
            throw AppError.dataError(.fetchFailed)
        }
        return mockResults
    }
    
    func searchProducts(
        query: String,
        sortOption: ProductSortOption
    ) async throws -> [ProductModel] {
        if shouldThrowError {
            throw AppError.dataError(.fetchFailed)
        }
        return mockResults
    }
    
    func execute(
        query: String,
        allProducts: [ProductModel],
        sortOption: ProductSortOption
    ) async throws -> [ProductModel] {
        if shouldThrowError {
            throw AppError.dataError(.fetchFailed)
        }
        return mockResults
    }
    
    func executeWithRepository(
        query: String,
        sortOption: ProductSortOption
    ) async throws -> [ProductModel] {
        if shouldThrowError {
            throw AppError.dataError(.fetchFailed)
        }
        return mockResults
    }
}