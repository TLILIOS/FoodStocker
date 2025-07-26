//
//  BaseViewModelTests.swift
//  FoodStockerTests
//
//  Tests unitaires pour BaseViewModel
//

import XCTest
@testable import FoodStocker

// MARK: - Mock ViewModel for Testing
@Observable
final class MockViewModel: BaseViewModel {
    var operationCallCount = 0
    var successCallCount = 0
    var errorCallCount = 0
    
    func simulateSuccess() async {
        await executeWithRetry(
            operation: { [weak self] in
                self?.operationCallCount += 1
                return "Success"
            },
            onSuccess: { [weak self] _ in
                self?.successCallCount += 1
            }
        )
    }
    
    func simulateError(shouldRetry: Bool = false) async {
        await executeWithRetry(
            operation: { [weak self] in
                self?.operationCallCount += 1
                throw AppError.dataError(.fetchFailed)
            },
            onSuccess: { [weak self] _ in
                self?.successCallCount += 1
            },
            shouldRetry: { _ in shouldRetry }
        )
    }
    
    func simulateRetriableError() async {
        var attempts = 0
        await executeWithRetry(
            operation: { [weak self] in
                self?.operationCallCount += 1
                attempts += 1
                if attempts < 3 {
                    throw AppError.dataError(.fetchFailed)
                }
                return "Success after retries"
            },
            onSuccess: { [weak self] _ in
                self?.successCallCount += 1
            }
        )
    }
}

// MARK: - BaseViewModel Tests
final class BaseViewModelTests: XCTestCase {
    
    private var sut: MockViewModel!
    
    override func setUp() {
        super.setUp()
        sut = MockViewModel()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleError_WithAppError_SetsError() {
        // Given
        let expectedError = AppError.dataError(.fetchFailed)
        
        // When
        sut.handleError(expectedError)
        
        // Then
        XCTAssertEqual(sut.error, expectedError)
    }
    
    func testHandleError_WithGenericError_ConvertsToAppError() {
        // Given
        let genericError = NSError(domain: "TestError", code: 1, userInfo: nil)
        
        // When
        sut.handleError(genericError)
        
        // Then
        XCTAssertNotNil(sut.error)
        if case .unknown = sut.error! {
            // Success
        } else {
            XCTFail("Expected unknown error type")
        }
    }
    
    func testClearError_RemovesError() {
        // Given
        sut.handleError(AppError.dataError(.fetchFailed))
        XCTAssertNotNil(sut.error)
        
        // When
        sut.clearError()
        
        // Then
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Loading State Tests
    
    func testExecuteWithRetry_SetsLoadingState() async {
        // Given
        XCTAssertFalse(sut.isLoading)
        
        // When
        await sut.simulateSuccess()
        
        // Then
        XCTAssertFalse(sut.isLoading) // Should be false after completion
        XCTAssertEqual(sut.operationCallCount, 1)
        XCTAssertEqual(sut.successCallCount, 1)
    }
    
    // MARK: - Retry Logic Tests
    
    func testExecuteWithRetry_WithRetriableError_RetriesOperation() async {
        // When
        await sut.simulateRetriableError()
        
        // Then
        XCTAssertEqual(sut.operationCallCount, 3) // Initial + 2 retries
        XCTAssertEqual(sut.successCallCount, 1) // Eventually succeeds
        XCTAssertNil(sut.error) // Error cleared on success
    }
    
    func testExecuteWithRetry_WithNonRetriableError_DoesNotRetry() async {
        // When
        await sut.simulateError(shouldRetry: false)
        
        // Then
        XCTAssertEqual(sut.operationCallCount, 1) // No retries
        XCTAssertEqual(sut.successCallCount, 0) // Never succeeds
        XCTAssertNotNil(sut.error) // Error is set
    }
    
    // MARK: - Validation Helper Tests
    
    func testValidateNotEmpty_WithValidValue_DoesNotThrow() {
        // Given
        let validValue = "Test"
        
        // When/Then
        XCTAssertNoThrow(try sut.validateNotEmpty(validValue, fieldName: "test"))
    }
    
    func testValidateNotEmpty_WithEmptyValue_Throws() {
        // Given
        let emptyValue = ""
        
        // When/Then
        XCTAssertThrowsError(try sut.validateNotEmpty(emptyValue, fieldName: "test")) { error in
            XCTAssertEqual(error as? AppError, AppError.validationError(.emptyName))
        }
    }
    
    func testValidatePositiveQuantity_WithPositiveValue_DoesNotThrow() {
        // Given
        let positiveValue = 1.5
        
        // When/Then
        XCTAssertNoThrow(try sut.validatePositiveQuantity(positiveValue))
    }
    
    func testValidatePositiveQuantity_WithZeroValue_Throws() {
        // Given
        let zeroValue = 0.0
        
        // When/Then
        XCTAssertThrowsError(try sut.validatePositiveQuantity(zeroValue)) { error in
            XCTAssertEqual(error as? AppError, AppError.validationError(.invalidQuantity))
        }
    }
    
    func testValidateFutureDate_WithFutureDate_DoesNotThrow() {
        // Given
        let futureDate = Date().addingTimeInterval(3600) // 1 hour in future
        
        // When/Then
        XCTAssertNoThrow(try sut.validateFutureDate(futureDate, fieldName: "test"))
    }
    
    func testValidateFutureDate_WithPastDate_Throws() {
        // Given
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour in past
        
        // When/Then
        XCTAssertThrowsError(try sut.validateFutureDate(pastDate, fieldName: "test")) { error in
            XCTAssertEqual(error as? AppError, AppError.validationError(.pastExpirationDate))
        }
    }
    
    // MARK: - Retry Policy Tests
    
    func testIsRetriableError_WithFetchFailed_ReturnsTrue() {
        // Given
        let error = AppError.dataError(.fetchFailed)
        
        // When
        let isRetriable = sut.isRetriableError(error)
        
        // Then
        XCTAssertTrue(isRetriable)
    }
    
    func testIsRetriableError_WithCoreDataError_ReturnsFalse() {
        // Given
        let error = AppError.dataError(.coreDataError("Test"))
        
        // When
        let isRetriable = sut.isRetriableError(error)
        
        // Then
        XCTAssertFalse(isRetriable)
    }
    
    func testIsRetriableError_WithNetworkTimeout_ReturnsTrue() {
        // Given
        let error = URLError(.timedOut)
        
        // When
        let isRetriable = sut.isRetriableError(error)
        
        // Then
        XCTAssertTrue(isRetriable)
    }
}

// MARK: - Performance Tests
extension BaseViewModelTests {
    
    func testPerformanceOfRetryLogic() {
        measure {
            let expectation = expectation(description: "Retry performance")
            
            Task {
                await sut.simulateRetriableError()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}