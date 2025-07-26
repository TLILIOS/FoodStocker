//
//  AlertsViewModelTests.swift
//  FoodStockerTests
//
//  Tests unitaires pour AlertsViewModel
//

import XCTest
@testable import FoodStocker

@MainActor
final class AlertsViewModelTests: XCTestCase {
    
    // MARK: - Properties
    private var sut: AlertsViewModel!
    private var mockManageAlertsUseCase: MockManageExpirationAlertsUseCase!
    private var mockDeleteUseCase: MockDeleteProductUseCase!
    
    // MARK: - Test Data
    private let expiredProduct = ProductModel(
        name: "Pommes Expirées",
        quantity: 2.0,
        unit: "kg",
        category: .fruits,
        location: .pantry,
        arrivalDate: Date().addingTimeInterval(-5 * 24 * 60 * 60),
        expirationDate: Date().addingTimeInterval(-2 * 24 * 60 * 60), // Expired 2 days ago
        lotNumber: "LOT001"
    )
    
    private let soonExpiredProduct = ProductModel(
        name: "Lait Bientôt Expiré",
        quantity: 1.0,
        unit: "L",
        category: .dairy,
        location: .refrigerator,
        arrivalDate: Date().addingTimeInterval(-3 * 24 * 60 * 60),
        expirationDate: Date().addingTimeInterval(1 * 24 * 60 * 60), // Expires tomorrow
        lotNumber: "LOT002"
    )
    
    private let anotherExpiredProduct = ProductModel(
        name: "Yaourt Expiré",
        quantity: 4.0,
        unit: "unité",
        category: .dairy,
        location: .refrigerator,
        arrivalDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
        expirationDate: Date().addingTimeInterval(-1 * 24 * 60 * 60), // Expired yesterday
        lotNumber: "LOT003"
    )
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        
        mockManageAlertsUseCase = MockManageExpirationAlertsUseCase()
        mockDeleteUseCase = MockDeleteProductUseCase()
        
        // Setup mock alerts
        mockManageAlertsUseCase.mockExpiredProducts = [expiredProduct, anotherExpiredProduct]
        mockManageAlertsUseCase.mockSoonExpiredProducts = [soonExpiredProduct]
        
        sut = AlertsViewModel(
            manageAlertsUseCase: mockManageAlertsUseCase,
            deleteProductUseCase: mockDeleteUseCase
        )
    }
    
    override func tearDown() {
        sut = nil
        mockManageAlertsUseCase = nil
        mockDeleteUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        // Then
        XCTAssertEqual(sut.expiredProducts.count, 0)
        XCTAssertEqual(sut.soonExpiredProducts.count, 0)
        XCTAssertEqual(sut.totalAlertsCount, 0)
        XCTAssertFalse(sut.hasAlerts)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Load Alerts Tests
    
    func testLoadAlerts_Success_UpdatesProductLists() async {
        // When
        await sut.loadAlerts()
        
        // Then
        XCTAssertEqual(sut.expiredProducts.count, 2)
        XCTAssertEqual(sut.soonExpiredProducts.count, 1)
        XCTAssertEqual(sut.totalAlertsCount, 3)
        XCTAssertTrue(sut.hasAlerts)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        
        // Verify specific products
        XCTAssertTrue(sut.expiredProducts.contains { $0.name == "Pommes Expirées" })
        XCTAssertTrue(sut.expiredProducts.contains { $0.name == "Yaourt Expiré" })
        XCTAssertTrue(sut.soonExpiredProducts.contains { $0.name == "Lait Bientôt Expiré" })
    }
    
    func testLoadAlerts_Failure_SetsError() async {
        // Given
        mockManageAlertsUseCase.shouldThrowError = true
        
        // When
        await sut.loadAlerts()
        
        // Then
        XCTAssertEqual(sut.expiredProducts.count, 0)
        XCTAssertEqual(sut.soonExpiredProducts.count, 0)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLoadAlerts_WithNoAlerts_UpdatesEmptyLists() async {
        // Given
        mockManageAlertsUseCase.mockExpiredProducts = []
        mockManageAlertsUseCase.mockSoonExpiredProducts = []
        
        // When
        await sut.loadAlerts()
        
        // Then
        XCTAssertEqual(sut.expiredProducts.count, 0)
        XCTAssertEqual(sut.soonExpiredProducts.count, 0)
        XCTAssertEqual(sut.totalAlertsCount, 0)
        XCTAssertFalse(sut.hasAlerts)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testRefreshAlerts_CallsLoadAlerts() async {
        // Given
        await sut.loadAlerts()
        XCTAssertEqual(sut.totalAlertsCount, 3)
        
        // When
        await sut.refreshAlerts()
        
        // Then
        XCTAssertEqual(sut.totalAlertsCount, 3)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Delete Product Tests
    
    func testDeleteProduct_Success_RemovesProductAndReloads() async {
        // Given
        await sut.loadAlerts()
        let productToDelete = sut.expiredProducts.first!
        let initialTotalCount = sut.totalAlertsCount
        
        // When
        await sut.deleteProduct(productToDelete)
        
        // Then
        XCTAssertTrue(mockDeleteUseCase.deletedProductIds.contains(productToDelete.id))
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testDeleteProduct_Failure_SetsError() async {
        // Given
        await sut.loadAlerts()
        let productToDelete = sut.expiredProducts.first!
        mockDeleteUseCase.shouldThrowError = true
        
        // When
        await sut.deleteProduct(productToDelete)
        
        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Dismiss Product Tests
    
    func testDismissProduct_FromExpiredList_RemovesFromLocalList() async {
        // Given
        await sut.loadAlerts()
        let productToDismiss = sut.expiredProducts.first!
        let initialExpiredCount = sut.expiredProducts.count
        
        // When
        await sut.dismissProduct(productToDismiss)
        
        // Then
        XCTAssertEqual(sut.expiredProducts.count, initialExpiredCount - 1)
        XCTAssertFalse(sut.expiredProducts.contains { $0.id == productToDismiss.id })
        XCTAssertTrue(mockManageAlertsUseCase.dismissedProducts.contains { $0.id == productToDismiss.id })
    }
    
    func testDismissProduct_FromSoonExpiredList_RemovesFromLocalList() async {
        // Given
        await sut.loadAlerts()
        let productToDismiss = sut.soonExpiredProducts.first!
        let initialSoonExpiredCount = sut.soonExpiredProducts.count
        
        // When
        await sut.dismissProduct(productToDismiss)
        
        // Then
        XCTAssertEqual(sut.soonExpiredProducts.count, initialSoonExpiredCount - 1)
        XCTAssertFalse(sut.soonExpiredProducts.contains { $0.id == productToDismiss.id })
        XCTAssertTrue(mockManageAlertsUseCase.dismissedProducts.contains { $0.id == productToDismiss.id })
    }
    
    func testDismissProduct_UpdatesTotalAlertsCount() async {
        // Given
        await sut.loadAlerts()
        let initialTotalCount = sut.totalAlertsCount
        let productToDismiss = sut.expiredProducts.first!
        
        // When
        await sut.dismissProduct(productToDismiss)
        
        // Then
        XCTAssertEqual(sut.totalAlertsCount, initialTotalCount - 1)
    }
    
    func testDismissProduct_WithError_HandlesGracefully() async {
        // Given
        await sut.loadAlerts()
        let productToDismiss = sut.expiredProducts.first!
        mockManageAlertsUseCase.shouldThrowError = true
        
        // When
        await sut.dismissProduct(productToDismiss)
        
        // Then
        XCTAssertNotNil(sut.error)
        
        // Product should still be removed from local list even if use case fails
        XCTAssertFalse(sut.expiredProducts.contains { $0.id == productToDismiss.id })
    }
    
    // MARK: - Alert Type Tests
    
    func testGetAlertTypeForProduct_WithExpiredProduct_ReturnsExpired() async {
        // Given
        await sut.loadAlerts()
        let expiredProduct = sut.expiredProducts.first!
        
        // When
        let alertType = sut.getAlertTypeForProduct(expiredProduct)
        
        // Then
        XCTAssertEqual(alertType, .expired)
    }
    
    func testGetAlertTypeForProduct_WithSoonExpiredProduct_ReturnsSoonExpired() async {
        // Given
        await sut.loadAlerts()
        let soonExpiredProduct = sut.soonExpiredProducts.first!
        
        // When
        let alertType = sut.getAlertTypeForProduct(soonExpiredProduct)
        
        // Then
        XCTAssertEqual(alertType, .soonExpired)
    }
    
    func testGetAlertTypeForProduct_WithUnknownProduct_ReturnsUnknown() async {
        // Given
        await sut.loadAlerts()
        let unknownProduct = ProductModel(
            name: "Unknown",
            quantity: 1.0,
            unit: "kg",
            category: .fruits,
            location: .pantry,
            arrivalDate: Date(),
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            lotNumber: "UNKNOWN"
        )
        
        // When
        let alertType = sut.getAlertTypeForProduct(unknownProduct)
        
        // Then
        XCTAssertEqual(alertType, .unknown)
    }
    
    // MARK: - Alert Count Properties Tests
    
    func testTotalAlertsCount_WithBothExpiredAndSoonExpired_ReturnsSum() async {
        // When
        await sut.loadAlerts()
        
        // Then
        XCTAssertEqual(sut.totalAlertsCount, 3) // 2 expired + 1 soon expired
    }
    
    func testTotalAlertsCount_WithOnlyExpired_ReturnsExpiredCount() async {
        // Given
        mockManageAlertsUseCase.mockSoonExpiredProducts = []
        
        // When
        await sut.loadAlerts()
        
        // Then
        XCTAssertEqual(sut.totalAlertsCount, 2) // Only expired products
    }
    
    func testTotalAlertsCount_WithOnlySoonExpired_ReturnsSoonExpiredCount() async {
        // Given
        mockManageAlertsUseCase.mockExpiredProducts = []
        
        // When
        await sut.loadAlerts()
        
        // Then
        XCTAssertEqual(sut.totalAlertsCount, 1) // Only soon expired products
    }
    
    func testHasAlerts_WithAlerts_ReturnsTrue() async {
        // When
        await sut.loadAlerts()
        
        // Then
        XCTAssertTrue(sut.hasAlerts)
    }
    
    func testHasAlerts_WithoutAlerts_ReturnsFalse() async {
        // Given
        mockManageAlertsUseCase.mockExpiredProducts = []
        mockManageAlertsUseCase.mockSoonExpiredProducts = []
        
        // When
        await sut.loadAlerts()
        
        // Then
        XCTAssertFalse(sut.hasAlerts)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError_RemovesError() async {
        // Given
        mockManageAlertsUseCase.shouldThrowError = true
        await sut.loadAlerts()
        XCTAssertNotNil(sut.error)
        
        // When
        sut.clearError()
        
        // Then
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentOperations_DoNotCrash() async {
        // Given
        let expectation1 = expectation(description: "Load alerts")
        let expectation2 = expectation(description: "Refresh alerts")
        let expectation3 = expectation(description: "Delete product")
        
        // When - Execute multiple operations concurrently
        Task {
            await sut.loadAlerts()
            expectation1.fulfill()
        }
        
        Task {
            await sut.refreshAlerts()
            expectation2.fulfill()
        }
        
        Task {
            await sut.loadAlerts()
            if !sut.expiredProducts.isEmpty {
                await sut.deleteProduct(sut.expiredProducts.first!)
            }
            expectation3.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation1, expectation2, expectation3], timeout: 5.0)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Multiple Dismiss Operations Tests
    
    func testMultipleDismissOperations_UpdatesCountsCorrectly() async {
        // Given
        await sut.loadAlerts()
        let initialTotalCount = sut.totalAlertsCount
        let firstProductToDismiss = sut.expiredProducts.first!
        let secondProductToDismiss = sut.soonExpiredProducts.first!
        
        // When
        await sut.dismissProduct(firstProductToDismiss)
        await sut.dismissProduct(secondProductToDismiss)
        
        // Then
        XCTAssertEqual(sut.totalAlertsCount, initialTotalCount - 2)
        XCTAssertFalse(sut.expiredProducts.contains { $0.id == firstProductToDismiss.id })
        XCTAssertFalse(sut.soonExpiredProducts.contains { $0.id == secondProductToDismiss.id })
    }
    
    func testDismissAllProducts_ResultsInNoAlerts() async {
        // Given
        await sut.loadAlerts()
        let allProducts = sut.expiredProducts + sut.soonExpiredProducts
        
        // When
        for product in allProducts {
            await sut.dismissProduct(product)
        }
        
        // Then
        XCTAssertEqual(sut.totalAlertsCount, 0)
        XCTAssertFalse(sut.hasAlerts)
        XCTAssertEqual(sut.expiredProducts.count, 0)
        XCTAssertEqual(sut.soonExpiredProducts.count, 0)
    }
}

// MARK: - Alert Type Tests
extension AlertsViewModelTests {
    
    func testAlertType_Properties() {
        // Test expired alert type
        XCTAssertEqual(AlertType.expired.title, "Produits expirés")
        XCTAssertEqual(AlertType.expired.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(AlertType.expired.color, .red)
        XCTAssertEqual(AlertType.expired.priority, 0)
        
        // Test soon expired alert type
        XCTAssertEqual(AlertType.soonExpired.title, "Expiration proche")
        XCTAssertEqual(AlertType.soonExpired.icon, "clock.badge.exclamationmark.fill")
        XCTAssertEqual(AlertType.soonExpired.color, .orange)
        XCTAssertEqual(AlertType.soonExpired.priority, 1)
        
        // Test unknown alert type
        XCTAssertEqual(AlertType.unknown.title, "Autres alertes")
        XCTAssertEqual(AlertType.unknown.icon, "info.circle.fill")
        XCTAssertEqual(AlertType.unknown.color, .gray)
        XCTAssertEqual(AlertType.unknown.priority, 2)
    }
    
    func testAlertType_PriorityOrdering() {
        // Then
        XCTAssertTrue(AlertType.expired.priority < AlertType.soonExpired.priority)
        XCTAssertTrue(AlertType.soonExpired.priority < AlertType.unknown.priority)
    }
}

// MARK: - Performance Tests
extension AlertsViewModelTests {
    
    func testPerformanceOfLoadAlerts() {
        // Given
        let manyExpiredProducts = Array(repeating: expiredProduct, count: 50)
        let manySoonExpiredProducts = Array(repeating: soonExpiredProduct, count: 50)
        mockManageAlertsUseCase.mockExpiredProducts = manyExpiredProducts
        mockManageAlertsUseCase.mockSoonExpiredProducts = manySoonExpiredProducts
        
        // When/Then
        measure {
            let expectation = expectation(description: "Load alerts performance")
            Task {
                await sut.loadAlerts()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformanceOfMultipleDismiss() async {
        // Given
        let manyProducts = Array(repeating: expiredProduct, count: 20)
        mockManageAlertsUseCase.mockExpiredProducts = manyProducts
        await sut.loadAlerts()
        
        // When/Then
        measure {
            let expectation = expectation(description: "Multiple dismiss performance")
            Task {
                for product in sut.expiredProducts.prefix(10) {
                    await sut.dismissProduct(product)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
}