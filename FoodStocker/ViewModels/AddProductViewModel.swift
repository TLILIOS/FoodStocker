import Foundation
import Observation
import os.log

// MARK: - Add Product View Model
@Observable
final class AddProductViewModel: BaseViewModel {
    
    // MARK: - Form Properties
    var name = ""
    var quantity = ""
    var selectedUnit = "kg"
    var selectedCategory: ProductCategory = .fruits
    var selectedLocation: ProductLocation = .refrigerator
    var expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // Default: 7 days from now
    var lotNumber = ""
    
    // MARK: - UI State
    var isShowingScanner = false
    private(set) var isGeneratingLot = false
    private(set) var validationErrors: [ValidationError] = []
    
    var isFormValid: Bool {
        validationErrors.isEmpty && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var hasValidationErrors: Bool {
        !validationErrors.isEmpty
    }
    
    // MARK: - Constants
    let availableUnits = ["kg", "g", "L", "mL", "unité", "boîte", "paquet", "bouteille"]
    
    // MARK: - Private Properties - Use Cases
    private let addProductUseCase: AddProductUseCaseProtocol
    
    // MARK: - Initialization
    init(
        addProductUseCase: AddProductUseCaseProtocol
    ) {
        self.addProductUseCase = addProductUseCase
        super.init(category: "AddProductViewModel")
    }
    
    // MARK: - Public Methods
    @MainActor
    func addProduct() async -> Bool {
        // Validate form first
        validateForm()
        
        guard validationErrors.isEmpty else {
            FoodStockerLogger.logWarning("Validation échouée: \(validationErrors)", category: .viewModel)
            return false
        }
        
        var success = false
        
        await executeWithRetry(
            operation: { [weak self] in
                guard let self = self else { throw AppError.unknown("Self deallocated") }
                
                let product = self.createProductFromForm()
                return try await self.addProductUseCase.execute(product)
            },
            onSuccess: { [weak self] product in
                FoodStockerLogger.logSuccess("Produit ajouté: \(product.name)", category: .viewModel)
                self?.resetForm()
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
    }
    
    func resetForm() {
        name = ""
        quantity = ""
        selectedUnit = "kg"
        selectedCategory = .fruits
        selectedLocation = .refrigerator
        expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        lotNumber = ""
        validationErrors.removeAll()
        clearError()
    }
    
    // clearError() héritée de BaseViewModel
    
    // MARK: - Scanner Management
    @MainActor
    func showScanner() {
        print("🔍 SCANNER: showScanner() appelée - État actuel: \(isShowingScanner)")
        // S'assurer qu'on est dans un état propre avant d'ouvrir
        guard !isShowingScanner else { 
            print("⚠️ Scanner déjà ouvert, ignorer")
            return 
        }
        isShowingScanner = true
        print("✅ Scanner ouvert")
    }
    
    @MainActor
    func hideScanner() {
        print("🔍 SCANNER: hideScanner() appelée - État actuel: \(isShowingScanner)")
        // Ne pas utiliser guard pour éviter les logs d'avertissement répétés
        if isShowingScanner {
            isShowingScanner = false
            print("✅ Scanner fermé")
        } else {
            print("ℹ️ Scanner déjà fermé - pas d'action nécessaire")
        }
    }
    
    @MainActor
    func updateLotNumberFromScan(_ scannedCode: String) {
        print("📝 SCANNER: Code scanné: \(scannedCode)")
        // Mettre à jour le numéro de lot
        lotNumber = scannedCode
        // Fermer le scanner après un scan réussi
        hideScanner()
    }
    
    // MARK: - Lot Number Generation
    func generateRandomLotNumber() {
        print("🎲 GENERATOR: generateRandomLotNumber() appelée")
        
        // Éviter les générations multiples simultanées
        guard !isGeneratingLot else {
            print("⚠️ Génération déjà en cours, ignorer")
            return
        }
        
        // Utiliser Task normal au lieu de Task.detached
        Task { @MainActor in
            self.isGeneratingLot = true
            
            // Génération du numéro de lot
            let newLotNumber = "LOT\(Int.random(in: 1000...9999))"
            
            // Mise à jour
            self.lotNumber = newLotNumber
            print("✅ Nouveau numéro de lot généré: \(newLotNumber)")
            
            // Valider le formulaire
            self.validateForm()
            
            // Réinitialiser le flag
            self.isGeneratingLot = false
        }
    }
    
    // MARK: - Async Validation
    private func asyncValidateForm() async {
        // Validation asynchrone pour éviter les blocages du main thread
        validateForm()
    }
    
    // MARK: - Private Methods
    private func createProductFromForm() -> ProductModel {
        return ProductModel(
            name: name.trimmingCharacters(in: .whitespaces),
            quantity: safeParsedQuantity(),
            unit: selectedUnit,
            category: selectedCategory,
            location: selectedLocation,
            arrivalDate: Date(),
            expirationDate: expirationDate,
            lotNumber: lotNumber.trimmingCharacters(in: .whitespaces)
        )
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

// MARK: - Form Validation Extensions
extension AddProductViewModel {
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
}

// MARK: - Form Field
enum FormField {
    case name
    case quantity
    case expirationDate
    case lotNumber
}

// MARK: - Mock View Model for Previews
extension AddProductViewModel {
    static func mock() -> AddProductViewModel {
        let viewModel = AddProductViewModel(
            addProductUseCase: MockAddProductUseCase()
        )
        
        // Pre-fill with sample data for preview
        viewModel.name = "Pommes"
        viewModel.quantity = "2.5"
        viewModel.selectedCategory = .fruits
        viewModel.selectedLocation = .pantry
        viewModel.lotNumber = "LOT1234"
        
        return viewModel
    }
}