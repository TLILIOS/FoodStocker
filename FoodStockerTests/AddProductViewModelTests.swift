//
//  AddProductViewModelTests.swift
//  FoodStockerTests
//
//  Tests unitaires pour AddProductViewModel
//

import XCTest
@testable import FoodStocker

@MainActor
final class AddProductViewModelTests: XCTestCase {
    
    // MARK: - Properties
    private var sut: AddProductViewModel!
    private var mockAddProductUseCase: MockAddProductUseCase!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        
        mockAddProductUseCase = MockAddProductUseCase()
        sut = AddProductViewModel(addProductUseCase: mockAddProductUseCase)
    }
    
    override func tearDown() {
        sut = nil
        mockAddProductUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        // Then
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.quantity, "")
        XCTAssertEqual(sut.selectedUnit, "kg")
        XCTAssertEqual(sut.selectedCategory, .fruits)
        XCTAssertEqual(sut.selectedLocation, .refrigerator)
        XCTAssertEqual(sut.lotNumber, "")
        XCTAssertFalse(sut.isShowingScanner)
        XCTAssertEqual(sut.validationErrors.count, 0)
        XCTAssertFalse(sut.isFormValid)
        XCTAssertFalse(sut.hasValidationErrors)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Form Validation Tests
    
    func testValidateForm_WithValidData_PassesValidation() {
        // Given
        sut.name = "Test Product"
        sut.quantity = "2.5"
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = "LOT123"
        
        // When
        sut.validateForm()
        
        // Then
        XCTAssertEqual(sut.validationErrors.count, 0)
        XCTAssertTrue(sut.isFormValid)
        XCTAssertFalse(sut.hasValidationErrors)
    }
    
    func testValidateForm_WithEmptyName_FailsValidation() {
        // Given
        sut.name = ""
        sut.quantity = "2.5"
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = "LOT123"
        
        // When
        sut.validateForm()
        
        // Then
        XCTAssertTrue(sut.validationErrors.contains(.emptyName))
        XCTAssertFalse(sut.isFormValid)
        XCTAssertTrue(sut.hasValidationErrors)
    }
    
    func testValidateForm_WithWhitespaceOnlyName_FailsValidation() {
        // Given
        sut.name = "   "
        sut.quantity = "2.5"
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = "LOT123"
        
        // When
        sut.validateForm()
        
        // Then
        XCTAssertTrue(sut.validationErrors.contains(.emptyName))
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testValidateForm_WithInvalidQuantity_FailsValidation() {
        // Given
        sut.name = "Test Product"
        sut.quantity = "0"
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = "LOT123"
        
        // When
        sut.validateForm()
        
        // Then
        XCTAssertTrue(sut.validationErrors.contains(.invalidQuantity))
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testValidateForm_WithEmptyQuantity_FailsValidation() {
        // Given
        sut.name = "Test Product"
        sut.quantity = ""
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = "LOT123"
        
        // When
        sut.validateForm()
        
        // Then
        XCTAssertTrue(sut.validationErrors.contains(.invalidQuantity))
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testValidateForm_WithNegativeQuantity_FailsValidation() {
        // Given
        sut.name = "Test Product"
        sut.quantity = "-1.5"
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = "LOT123"
        
        // When
        sut.validateForm()
        
        // Then
        XCTAssertTrue(sut.validationErrors.contains(.invalidQuantity))
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testValidateForm_WithPastExpirationDate_FailsValidation() {
        // Given
        sut.name = "Test Product"
        sut.quantity = "2.5"
        sut.expirationDate = Date().addingTimeInterval(-24 * 60 * 60) // Yesterday
        sut.lotNumber = "LOT123"
        
        // When
        sut.validateForm()
        
        // Then
        XCTAssertTrue(sut.validationErrors.contains(.pastExpirationDate))
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testValidateForm_WithEmptyLotNumber_FailsValidation() {
        // Given
        sut.name = "Test Product"
        sut.quantity = "2.5"
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = ""
        
        // When
        sut.validateForm()
        
        // Then
        XCTAssertTrue(sut.validationErrors.contains(.emptyLotNumber))
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testValidateForm_WithWhitespaceOnlyLotNumber_FailsValidation() {
        // Given
        sut.name = "Test Product"
        sut.quantity = "2.5"
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = "   "
        
        // When
        sut.validateForm()
        
        // Then
        XCTAssertTrue(sut.validationErrors.contains(.emptyLotNumber))
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testValidateForm_WithMultipleErrors_ReportsAllErrors() {
        // Given
        sut.name = ""
        sut.quantity = "0"
        sut.expirationDate = Date().addingTimeInterval(-24 * 60 * 60)
        sut.lotNumber = ""
        
        // When
        sut.validateForm()
        
        // Then
        XCTAssertTrue(sut.validationErrors.contains(.emptyName))
        XCTAssertTrue(sut.validationErrors.contains(.invalidQuantity))
        XCTAssertTrue(sut.validationErrors.contains(.pastExpirationDate))
        XCTAssertTrue(sut.validationErrors.contains(.emptyLotNumber))
        XCTAssertEqual(sut.validationErrors.count, 4)
        XCTAssertFalse(sut.isFormValid)
    }
    
    // MARK: - Add Product Tests
    
    func testAddProduct_WithValidData_Succeeds() async {
        // Given
        setupValidProduct()
        
        // When
        let result = await sut.addProduct()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockAddProductUseCase.addedProducts.count, 1)
        XCTAssertEqual(mockAddProductUseCase.addedProducts.first?.name, "Test Product")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        
        // Form should be reset after successful addition
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.quantity, "")
        XCTAssertEqual(sut.lotNumber, "")
    }
    
    func testAddProduct_WithInvalidData_Fails() async {
        // Given - Invalid data (empty name)
        sut.name = ""
        sut.quantity = "2.5"
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = "LOT123"
        
        // When
        let result = await sut.addProduct()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockAddProductUseCase.addedProducts.count, 0)
        XCTAssertTrue(sut.hasValidationErrors)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testAddProduct_WithUseCaseError_Fails() async {
        // Given
        setupValidProduct()
        mockAddProductUseCase.shouldThrowError = true
        
        // When
        let result = await sut.addProduct()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
        
        // Form should not be reset on error
        XCTAssertEqual(sut.name, "Test Product")
    }
    
    func testAddProduct_WithValidationError_Fails() async {
        // Given
        setupValidProduct()
        mockAddProductUseCase.shouldThrowValidationError = true
        
        // When
        let result = await sut.addProduct()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Reset Form Tests
    
    func testResetForm_ClearsAllFields() {
        // Given
        sut.name = "Test Product"
        sut.quantity = "2.5"
        sut.selectedUnit = "L"
        sut.selectedCategory = .meat
        sut.selectedLocation = .freezer
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = "LOT123"
        sut.handleError(AppError.dataError(.saveFailed))
        sut.validateForm()
        
        // When
        sut.resetForm()
        
        // Then
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.quantity, "")
        XCTAssertEqual(sut.selectedUnit, "kg")
        XCTAssertEqual(sut.selectedCategory, .fruits)
        XCTAssertEqual(sut.selectedLocation, .refrigerator)
        XCTAssertEqual(sut.lotNumber, "")
        XCTAssertEqual(sut.validationErrors.count, 0)
        XCTAssertNil(sut.error)
        
        // Expiration date should be reset to 7 days from now
        let sevenDaysFromNow = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let timeDifference = abs(sut.expirationDate.timeIntervalSince(sevenDaysFromNow))
        XCTAssertTrue(timeDifference < 60) // Within 1 minute
    }
    
    // MARK: - Scanner Tests
    
    func testShowScanner_SetsShowingScannerToTrue() {
        // Given
        XCTAssertFalse(sut.isShowingScanner)
        
        // When
        sut.showScanner()
        
        // Then
        XCTAssertTrue(sut.isShowingScanner)
    }
    
    func testHideScanner_SetsShowingScannerToFalse() {
        // Given
        sut.showScanner()
        XCTAssertTrue(sut.isShowingScanner)
        
        // When
        sut.hideScanner()
        
        // Then
        XCTAssertFalse(sut.isShowingScanner)
    }
    
    func testUpdateLotNumberFromScan_UpdatesLotNumberAndHidesScanner() {
        // Given
        let scannedCode = "123456789"
        sut.showScanner()
        XCTAssertTrue(sut.isShowingScanner)
        
        // When
        sut.updateLotNumberFromScan(scannedCode)
        
        // Then
        XCTAssertEqual(sut.lotNumber, scannedCode)
        XCTAssertFalse(sut.isShowingScanner)
    }
    
    func testGenerateRandomLotNumber_GeneratesValidLotNumber() {
        // Given
        XCTAssertEqual(sut.lotNumber, "")
        
        // When
        sut.generateRandomLotNumber()
        
        // Then
        XCTAssertTrue(sut.lotNumber.hasPrefix("LOT"))
        XCTAssertEqual(sut.lotNumber.count, 7) // "LOT" + 4 digits
        
        // Extract and verify the numeric part
        let numericPart = String(sut.lotNumber.dropFirst(3))
        XCTAssertNotNil(Int(numericPart))
        XCTAssertTrue(Int(numericPart)! >= 1000)
        XCTAssertTrue(Int(numericPart)! <= 9999)
    }
    
    func testGenerateRandomLotNumber_Multiple_GeneratesDifferentNumbers() {
        // When
        sut.generateRandomLotNumber()
        let firstLotNumber = sut.lotNumber
        
        sut.generateRandomLotNumber()
        let secondLotNumber = sut.lotNumber
        
        sut.generateRandomLotNumber()
        let thirdLotNumber = sut.lotNumber
        
        // Then
        // It's highly unlikely that all three would be the same
        let allSame = (firstLotNumber == secondLotNumber) && (secondLotNumber == thirdLotNumber)
        XCTAssertFalse(allSame)
    }
    
    // MARK: - Form Field Validation Helpers Tests
    
    func testGetValidationError_ForName_ReturnsCorrectError() {
        // Given
        sut.name = ""
        sut.validateForm()
        
        // When
        let error = sut.getValidationError(for: .name)
        
        // Then
        XCTAssertEqual(error, .emptyName)
    }
    
    func testGetValidationError_ForQuantity_ReturnsCorrectError() {
        // Given
        sut.quantity = "0"
        sut.validateForm()
        
        // When
        let error = sut.getValidationError(for: .quantity)
        
        // Then
        XCTAssertEqual(error, .invalidQuantity)
    }
    
    func testGetValidationError_ForExpirationDate_ReturnsCorrectError() {
        // Given
        sut.expirationDate = Date().addingTimeInterval(-24 * 60 * 60)
        sut.validateForm()
        
        // When
        let error = sut.getValidationError(for: .expirationDate)
        
        // Then
        XCTAssertEqual(error, .pastExpirationDate)
    }
    
    func testGetValidationError_ForLotNumber_ReturnsCorrectError() {
        // Given
        sut.lotNumber = ""
        sut.validateForm()
        
        // When
        let error = sut.getValidationError(for: .lotNumber)
        
        // Then
        XCTAssertEqual(error, .emptyLotNumber)
    }
    
    func testGetValidationError_ForValidField_ReturnsNil() {
        // Given
        setupValidProduct()
        sut.validateForm()
        
        // When
        let nameError = sut.getValidationError(for: .name)
        let quantityError = sut.getValidationError(for: .quantity)
        let dateError = sut.getValidationError(for: .expirationDate)
        let lotError = sut.getValidationError(for: .lotNumber)
        
        // Then
        XCTAssertNil(nameError)
        XCTAssertNil(quantityError)
        XCTAssertNil(dateError)
        XCTAssertNil(lotError)
    }
    
    func testHasError_ForFieldWithError_ReturnsTrue() {
        // Given
        sut.name = ""
        sut.validateForm()
        
        // When
        let hasError = sut.hasError(for: .name)
        
        // Then
        XCTAssertTrue(hasError)
    }
    
    func testHasError_ForValidField_ReturnsFalse() {
        // Given
        setupValidProduct()
        sut.validateForm()
        
        // When
        let hasError = sut.hasError(for: .name)
        
        // Then
        XCTAssertFalse(hasError)
    }
    
    // MARK: - Available Units Tests
    
    func testAvailableUnits_ContainsExpectedUnits() {
        // Then
        XCTAssertTrue(sut.availableUnits.contains("kg"))
        XCTAssertTrue(sut.availableUnits.contains("g"))
        XCTAssertTrue(sut.availableUnits.contains("L"))
        XCTAssertTrue(sut.availableUnits.contains("mL"))
        XCTAssertTrue(sut.availableUnits.contains("unité"))
        XCTAssertTrue(sut.availableUnits.contains("boîte"))
        XCTAssertTrue(sut.availableUnits.contains("paquet"))
        XCTAssertTrue(sut.availableUnits.contains("bouteille"))
    }
    
    // MARK: - Helper Methods
    
    private func setupValidProduct() {
        sut.name = "Test Product"
        sut.quantity = "2.5"
        sut.selectedUnit = "kg"
        sut.selectedCategory = .fruits
        sut.selectedLocation = .refrigerator
        sut.expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sut.lotNumber = "LOT123"
    }
}

// MARK: - Performance Tests
extension AddProductViewModelTests {
    
    func testPerformanceOfFormValidation() {
        // Given
        setupValidProduct()
        
        // When/Then
        measure {
            sut.validateForm()
        }
    }
    
    func testPerformanceOfAddProduct() {
        // Given
        setupValidProduct()
        
        // When/Then
        measure {
            let expectation = expectation(description: "Add product performance")
            Task {
                _ = await sut.addProduct()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
}