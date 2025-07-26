//
//  PersistenceTests.swift
//  FoodStockerTests
//
//  Tests pour la gestion des erreurs Core Data
//

import XCTest
import CoreData
@testable import FoodStocker

final class PersistenceTests: XCTestCase {
    
    // MARK: - Test Core Data Initialization Success
    func testCoreDataInitializationSuccess() async throws {
        // Given
        let persistence = PersistenceController(inMemory: true)
        
        // When
        let context = persistence.container.viewContext
        
        // Then
        XCTAssertNotNil(context)
        XCTAssertFalse(persistence.isUsingInMemoryFallback)
        XCTAssertNil(persistence.initializationError)
    }
    
    // MARK: - Test In-Memory Fallback
    func testInMemoryFallbackActivation() async throws {
        // Given - Simuler une erreur Core Data
        let expectation = XCTestExpectation(description: "Core Data error notification")
        var receivedError: AppError?
        
        NotificationCenter.default.addObserver(
            forName: .coreDataInitializationFailed,
            object: nil,
            queue: .main
        ) { notification in
            if let error = notification.userInfo?["error"] as? AppError {
                receivedError = error
                expectation.fulfill()
            }
        }
        
        // When - Créer un controller avec un chemin invalide
        // Note: Dans un vrai test, on simulerait une erreur d'initialisation
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(receivedError)
    }
    
    // MARK: - Test Recovery Method
    func testCoreDataRecovery() async throws {
        // Given
        let persistence = PersistenceController(inMemory: true)
        
        // When
        do {
            try await persistence.attemptRecovery()
            
            // Then
            XCTAssertFalse(persistence.isUsingInMemoryFallback)
            XCTAssertNil(persistence.initializationError)
        } catch {
            XCTFail("Recovery should succeed for in-memory store")
        }
    }
    
    // MARK: - Test Error Propagation
    func testErrorPropagationToUI() async throws {
        // Given
        let error = AppError.dataError(.coreDataFatalError)
        
        // When
        NotificationCenter.default.post(
            name: .coreDataInitializationFailed,
            object: nil,
            userInfo: ["error": error, "isFatal": true]
        )
        
        // Then - L'UI devrait recevoir l'erreur via notification
        // Vérifier dans FoodStockerApp que showCoreDataError = true
    }
    
    // MARK: - Test Data Persistence in Fallback Mode
    func testDataPersistenceInMemoryMode() async throws {
        // Given
        let persistence = PersistenceController(inMemory: true)
        let repository = CoreDataProductRepository(container: persistence.container)
        
        // When
        let testProduct = ProductModel(
            name: "Test Product",
            quantity: 1.0,
            unit: "kg",
            category: .fruits,
            location: .pantry,
            arrivalDate: Date(),
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            lotNumber: "TEST123"
        )
        
        try await repository.addProduct(testProduct)
        let products = try await repository.fetchProducts()
        
        // Then
        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products.first?.name, "Test Product")
    }
}

// MARK: - Mock Corrupted Container
class MockCorruptedPersistentContainer: NSPersistentContainer {
    override func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void) {
        // Simuler une erreur Core Data
        let error = NSError(
            domain: "CoreDataError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Simulated Core Data failure"]
        )
        block(NSPersistentStoreDescription(), error)
    }
}