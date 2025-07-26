//
//  ProductListViewModelTests.swift
//  FoodStockerTests
//
//  Tests unitaires pour ProductListViewModel
//

import XCTest
@testable import FoodStocker

@MainActor
final class ProductListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    private var sut: ProductListViewModel!
    private var mockSearchUseCase: MockSearchProductsUseCase!
    private var mockDeleteUseCase: MockDeleteProductUseCase!
    private var mockAlertsUseCase: MockManageExpirationAlertsUseCase!
    
    // MARK: - Test Data
    private let testProducts = [
        ProductModel(
            name: "Pommes",
            quantity: 2.5,
            unit: "kg",
            category: .fruits,
            location: .pantry,
            arrivalDate: Date().addingTimeInterval(-3 * 24 * 60 * 60),
            expirationDate: Date().addingTimeInterval(-1 * 24 * 60 * 60), // Expired
            lotNumber: "LOT1234"
        ),
        ProductModel(
            name: "Lait",
            quantity: 1.0,
            unit: "L",
            category: .dairy,
            location: .refrigerator,
            arrivalDate: Date().addingTimeInterval(-2 * 24 * 60 * 60),
            expirationDate: Date().addingTimeInterval(2 * 24 * 60 * 60), // Soon expired
            lotNumber: "LOT5678"
        ),
        ProductModel(
            name: "Carottes",
            quantity: 1.5,
            unit: "kg",
            category: .vegetables,
            location: .refrigerator,
            arrivalDate: Date().addingTimeInterval(-1 * 24 * 60 * 60),
            expirationDate: Date().addingTimeInterval(10 * 24 * 60 * 60), // Fresh
            lotNumber: "LOT9012"
        )
    ]
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        
        mockSearchUseCase = MockSearchProductsUseCase()
        mockDeleteUseCase = MockDeleteProductUseCase()
        mockAlertsUseCase = MockManageExpirationAlertsUseCase()
        
        mockSearchUseCase.mockResults = testProducts
        
        sut = ProductListViewModel(
            searchProductsUseCase: mockSearchUseCase,
            deleteProductUseCase: mockDeleteUseCase,
            manageAlertsUseCase: mockAlertsUseCase
        )
    }
    
    override func tearDown() {
        sut = nil
        mockSearchUseCase = nil
        mockDeleteUseCase = nil
        mockAlertsUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        // Then
        XCTAssertEqual(sut.products.count, 0)
        XCTAssertEqual(sut.filteredProducts.count, 0)
        XCTAssertEqual(sut.searchText, "")
        XCTAssertEqual(sut.sortOption, .name)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Load Products Tests
    
    func testLoadProducts_Success_UpdatesProductsAndFilteredProducts() async {
        // When
        await sut.loadProducts()
        
        // Then
        XCTAssertEqual(sut.products.count, 3)
        XCTAssertEqual(sut.filteredProducts.count, 3)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        
        // Verify products are sorted by name (default)
        XCTAssertEqual(sut.filteredProducts[0].name, "Carottes")
        XCTAssertEqual(sut.filteredProducts[1].name, "Lait")
        XCTAssertEqual(sut.filteredProducts[2].name, "Pommes")
    }
    
    func testLoadProducts_Failure_SetsError() async {
        // Given
        mockSearchUseCase.shouldThrowError = true
        
        // When
        await sut.loadProducts()
        
        // Then
        XCTAssertEqual(sut.products.count, 0)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testRefreshProducts_CallsLoadProducts() async {
        // Given
        await sut.loadProducts()
        XCTAssertEqual(sut.products.count, 3)
        
        // When
        await sut.refreshProducts()
        
        // Then
        XCTAssertEqual(sut.products.count, 3)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Search Tests
    
    func testSearchProducts_WithEmptyQuery_ShowsAllProducts() async {
        // Given
        await sut.loadProducts()
        
        // When
        await sut.searchProducts(query: "")
        
        // Then
        XCTAssertEqual(sut.filteredProducts.count, 3)
        XCTAssertEqual(sut.searchText, "")
    }
    
    func testSearchProducts_WithValidQuery_FiltersResults() async {
        // Given
        await sut.loadProducts()
        mockSearchUseCase.mockResults = [testProducts[0]] // Only "Pommes"
        
        // When
        await sut.searchProducts(query: "Pommes")
        
        // Then
        XCTAssertEqual(sut.searchText, "Pommes")
        XCTAssertEqual(sut.filteredProducts.count, 1)
        XCTAssertEqual(sut.filteredProducts.first?.name, "Pommes")
    }
    
    func testSearchProducts_WithSearchFailure_SetsError() async {
        // Given
        await sut.loadProducts()
        mockSearchUseCase.shouldThrowError = true
        
        // When
        await sut.searchProducts(query: "Error")
        
        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(sut.searchText, "Error")
    }
    
    // MARK: - Sorting Tests
    
    func testSortOption_ByExpirationDate_SortsCorrectly() async {
        // Given
        await sut.loadProducts()
        
        // When
        sut.sortOption = .expirationDate
        
        // Then
        // Should be sorted by expiration date (ascending)
        let firstProduct = sut.filteredProducts.first
        let lastProduct = sut.filteredProducts.last
        XCTAssertTrue(firstProduct!.expirationDate < lastProduct!.expirationDate)
    }
    
    func testSortOption_ByCategory_SortsCorrectly() async {
        // Given
        await sut.loadProducts()
        
        // When
        sut.sortOption = .category
        
        // Then
        // Should be sorted by category
        XCTAssertEqual(sut.filteredProducts[0].category, .dairy) // Lait
        XCTAssertEqual(sut.filteredProducts[1].category, .fruits) // Pommes
        XCTAssertEqual(sut.filteredProducts[2].category, .vegetables) // Carottes
    }
    
    // MARK: - Delete Product Tests
    
    func testDeleteProduct_Success_RemovesProductAndReloads() async {
        // Given
        await sut.loadProducts()
        let productToDelete = sut.products.first!
        let initialCount = sut.products.count
        
        // When
        await sut.deleteProduct(productToDelete)
        
        // Then
        XCTAssertTrue(mockDeleteUseCase.deletedProductIds.contains(productToDelete.id))
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testDeleteProduct_Failure_SetsError() async {
        // Given
        await sut.loadProducts()
        let productToDelete = sut.products.first!
        mockDeleteUseCase.shouldThrowError = true
        
        // When
        await sut.deleteProduct(productToDelete)
        
        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Alert Count Tests
    
    func testAlertProductsCount_ReturnsCorrectCount() async {
        // When
        await sut.loadProducts()
        
        // Then
        // Pommes (expired) + Lait (soon expired) = 2
        XCTAssertEqual(sut.alertProductsCount, 2)
    }
    
    func testExpiredProductsCount_ReturnsCorrectCount() async {
        // When
        await sut.loadProducts()
        
        // Then
        // Only Pommes is expired
        XCTAssertEqual(sut.expiredProductsCount, 1)
    }
    
    func testSoonExpiredProductsCount_ReturnsCorrectCount() async {
        // When
        await sut.loadProducts()
        
        // Then
        // Only Lait is soon expired
        XCTAssertEqual(sut.soonExpiredProductsCount, 1)
    }
    
    // MARK: - Get Product Tests
    
    func testGetProduct_WithValidId_ReturnsProduct() async {
        // Given
        await sut.loadProducts()
        let firstProduct = sut.products.first!
        
        // When
        let foundProduct = sut.getProduct(by: firstProduct.id)
        
        // Then
        XCTAssertNotNil(foundProduct)
        XCTAssertEqual(foundProduct?.id, firstProduct.id)
        XCTAssertEqual(foundProduct?.name, firstProduct.name)
    }
    
    func testGetProduct_WithInvalidId_ReturnsNil() async {
        // Given
        await sut.loadProducts()
        let invalidId = UUID()
        
        // When
        let foundProduct = sut.getProduct(by: invalidId)
        
        // Then
        XCTAssertNil(foundProduct)
    }
    
    // MARK: - Filter and Sort Integration Tests
    
    func testFilterAndSort_WithSearchTextAndSortOption_WorksTogether() async {
        // Given
        await sut.loadProducts()
        
        // When
        sut.searchText = "a" // Should match "Carottes" and "Lait"
        sut.sortOption = .expirationDate
        
        // Then
        // Should filter and then sort by expiration date
        XCTAssertEqual(sut.filteredProducts.count, 3) // All products contain 'a'
        
        // Should be sorted by expiration date
        let dates = sut.filteredProducts.map { $0.expirationDate }
        for i in 0..<(dates.count - 1) {
            XCTAssertTrue(dates[i] <= dates[i + 1])
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError_RemovesError() async {
        // Given
        mockSearchUseCase.shouldThrowError = true
        await sut.loadProducts()
        XCTAssertNotNil(sut.error)
        
        // When
        sut.clearError()
        
        // Then
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentOperations_DoNotCrash() async {
        // Given
        let expectation1 = expectation(description: "Load products")
        let expectation2 = expectation(description: "Search products")
        let expectation3 = expectation(description: "Refresh products")
        
        // When - Execute multiple operations concurrently
        Task {
            await sut.loadProducts()
            expectation1.fulfill()
        }
        
        Task {
            await sut.searchProducts(query: "test")
            expectation2.fulfill()
        }
        
        Task {
            await sut.refreshProducts()
            expectation3.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation1, expectation2, expectation3], timeout: 5.0)
        XCTAssertFalse(sut.isLoading)
    }
}

// MARK: - Performance Tests
extension ProductListViewModelTests {
    
    func testPerformanceOfLoadProducts() {
        // Given
        mockSearchUseCase.mockResults = Array(repeating: testProducts, count: 100).flatMap { $0 }
        
        // When/Then
        measure {
            let expectation = expectation(description: "Load performance")
            Task {
                await sut.loadProducts()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformanceOfFiltering() async {
        // Given
        mockSearchUseCase.mockResults = Array(repeating: testProducts, count: 100).flatMap { $0 }
        await sut.loadProducts()
        
        // When/Then
        measure {
            sut.searchText = "test"
        }
    }
}