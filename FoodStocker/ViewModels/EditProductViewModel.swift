//
//  EditProductViewModel.swift
//  FoodStocker
//
//  ViewModel pour l'édition de produits avec UpdateProductUseCase
//

import Foundation
import Observation
import os.log

// MARK: - Edit Product View Model
@Observable
final class EditProductViewModel: BaseViewModel {
    
    // MARK: - Form Properties
    var name = ""
    var quantity = ""
    var selectedUnit = "kg"
    var selectedCategory: ProductCategory = .fruits
    var selectedLocation: ProductLocation = .refrigerator
    var expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    var lotNumber = ""
    
    // MARK: - UI State
    private(set) var validationErrors: [ValidationError] = []
    private(set) var hasChanges = false
    private(set) var originalProduct: ProductModel
    
    var isFormValid: Bool {
        validationErrors.isEmpty && !name.trimmingCharacters(in: .whitespaces).isEmpty && hasChanges
    }
    
    var hasValidationErrors: Bool {
        !validationErrors.isEmpty
    }
    
    // MARK: - Constants
    let availableUnits = ["kg", "g", "L", "mL", "unité", "boîte", "paquet", "bouteille"]
    
    // MARK: - Private Properties - Use Cases
    private let updateProductUseCase: UpdateProductUseCaseProtocol
    
    // MARK: - Initialization
    init(
        product: ProductModel,
        updateProductUseCase: UpdateProductUseCaseProtocol
    ) {
        self.originalProduct = product
        self.updateProductUseCase = updateProductUseCase
        super.init(category: "EditProductViewModel")
        
        // Pre-fill form with existing data
        populateFormFromProduct(product)
        setupChangeTracking()
    }
    
    // MARK: - Public Methods
    @MainActor
    func updateProduct() async -> Bool {
        // Validate form first
        validateForm()
        
        guard validationErrors.isEmpty else {
            FoodStockerLogger.logWarning("Validation échouée: \(validationErrors)", category: .viewModel)
            return false
        }
        
        guard hasChanges else {
            FoodStockerLogger.logWarning("Aucune modification détectée", category: .viewModel)
            return false
        }
        
        var success = false
        
        await executeWithRetry(
            operation: { [weak self] in
                guard let self = self else { throw AppError.unknown("Self deallocated") }
                
                let updatedProduct = self.createUpdatedProductFromForm()
                return try await self.updateProductUseCase.execute(updatedProduct)
            },
            onSuccess: { [weak self] updatedProduct in
                FoodStockerLogger.logSuccess("Produit modifié: \(updatedProduct.name)", category: .viewModel)
                self?.originalProduct = updatedProduct
                self?.hasChanges = false
                success = true
            },
            shouldRetry: isRetriableError
        )
        
        return success
    }
    
    func validateForm() {
        validationErrors.removeAll()
        
        // Validate name
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors.append(.emptyName)
        }
        
        // Validate quantity
        if quantity.isEmpty {
            validationErrors.append(.invalidQuantity)
        } else if let quantityValue = Double(quantity) {
            if quantityValue <= 0 || quantityValue.isNaN || quantityValue.isInfinite {
                validationErrors.append(.invalidQuantity)
            }
        } else {
            validationErrors.append(.invalidQuantity)
        }
        
        // Validate expiration date
        if expirationDate < Date() {
            validationErrors.append(.pastExpirationDate)
        }
        
        // Validate lot number
        if lotNumber.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors.append(.emptyLotNumber)
        }
        
        // Check for changes
        checkForChanges()
    }
    
    func resetToOriginal() {
        populateFormFromProduct(originalProduct)
        validationErrors.removeAll()
        hasChanges = false
        clearError()
    }
    
    func hasUnsavedChanges() -> Bool {
        return hasChanges && isFormValid
    }
    
    // MARK: - Form Field Validation Helpers
    func getValidationError(for field: FormField) -> ValidationError? {
        switch field {
        case .name:
            return validationErrors.first { error in
                if case .emptyName = error { return true }
                return false
            }
        case .quantity:
            return validationErrors.first { error in
                if case .invalidQuantity = error { return true }
                return false
            }
        case .expirationDate:
            return validationErrors.first { error in
                if case .pastExpirationDate = error { return true }
                return false
            }
        case .lotNumber:
            return validationErrors.first { error in
                if case .emptyLotNumber = error { return true }
                return false
            }
        }
    }
    
    func hasError(for field: FormField) -> Bool {
        getValidationError(for: field) != nil
    }
    
    // MARK: - Private Methods
    private func populateFormFromProduct(_ product: ProductModel) {
        name = product.name
        quantity = String(product.quantity)
        selectedUnit = product.unit
        selectedCategory = product.category
        selectedLocation = product.location
        expirationDate = product.expirationDate
        lotNumber = product.lotNumber
    }
    
    private func createUpdatedProductFromForm() -> ProductModel {
        return ProductModel(
            id: originalProduct.id, // Keep same ID
            name: name.trimmingCharacters(in: .whitespaces),
            quantity: safeParsedQuantity(),
            unit: selectedUnit,
            category: selectedCategory,
            location: selectedLocation,
            arrivalDate: originalProduct.arrivalDate, // Keep original arrival date
            expirationDate: expirationDate,
            lotNumber: lotNumber.trimmingCharacters(in: .whitespaces)
        )
    }
    
    private func checkForChanges() {
        let currentProduct = createUpdatedProductFromForm()
        
        hasChanges = (
            currentProduct.name != originalProduct.name ||
            currentProduct.quantity != originalProduct.quantity ||
            currentProduct.unit != originalProduct.unit ||
            currentProduct.category != originalProduct.category ||
            currentProduct.location != originalProduct.location ||
            abs(currentProduct.expirationDate.timeIntervalSince(originalProduct.expirationDate)) > 60 || // 1 minute tolerance
            currentProduct.lotNumber != originalProduct.lotNumber
        )
    }
    
    private func setupChangeTracking() {
        // Initial check
        checkForChanges()
    }
    
    private func safeParsedQuantity() -> Double {
        guard let parsedQuantity = Double(quantity) else { return 0.0 }
        
        // Protection contre NaN et valeurs infinies
        if parsedQuantity.isNaN || parsedQuantity.isInfinite || parsedQuantity < 0 {
            return 0.0
        }
        
        return parsedQuantity
    }
}

// MARK: - Mock View Model for Previews
extension EditProductViewModel {
    static func mock(with product: ProductModel) -> EditProductViewModel {
        return EditProductViewModel(
            product: product,
            updateProductUseCase: MockUpdateProductUseCase()
        )
    }
}