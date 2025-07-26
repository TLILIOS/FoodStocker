//
//  FoodStockerApp.swift
//  FoodStocker
//
//  Created by TLiLi Hamdi on 24/07/2025.
//

import SwiftUI
import UserNotifications
import CoreData

@main
struct FoodStockerApp: App {
    // MARK: - Dependencies
    private let persistenceController = PersistenceController.shared
    private let notificationService: NotificationServiceProtocol
    private let productRepository: ProductRepositoryProtocol
    
    // MARK: - Use Cases
    private let searchProductsUseCase: SearchProductsUseCaseProtocol
    private let addProductUseCase: AddProductUseCaseProtocol
    private let deleteProductUseCase: DeleteProductUseCaseProtocol
    private let updateProductUseCase: UpdateProductUseCaseProtocol
    private let manageAlertsUseCase: ManageExpirationAlertsUseCaseProtocol
    
    // MARK: - View Models
    private let productListViewModel: ProductListViewModel
    private let alertsViewModel: AlertsViewModel
    private let addProductViewModel: AddProductViewModel
    
    // MARK: - Error Handling State
    @State private var showCoreDataError = false
    @State private var coreDataError: AppError?
    @State private var isInMemoryMode = false
    
    // MARK: - Notification Observers
    @State private var observers: [NSObjectProtocol] = []
    
    init() {
        // Initialize services
        self.notificationService = UserNotificationService()
        self.productRepository = CoreDataProductRepository(container: persistenceController.container)
        
        // Initialize Use Cases
        self.searchProductsUseCase = SearchProductsUseCase(
            productRepository: productRepository
        )
        
        self.addProductUseCase = AddProductUseCase(
            productRepository: productRepository,
            notificationService: notificationService
        )
        
        self.deleteProductUseCase = DeleteProductUseCase(
            productRepository: productRepository,
            notificationService: notificationService
        )
        
        self.updateProductUseCase = UpdateProductUseCase(
            productRepository: productRepository,
            notificationService: notificationService,
            addProductUseCase: self.addProductUseCase
        )
        
        self.manageAlertsUseCase = ManageExpirationAlertsUseCase(
            productRepository: productRepository,
            notificationService: notificationService
        )
        
        // Initialize view models with Use Cases injection
        self.productListViewModel = ProductListViewModel(
            searchProductsUseCase: searchProductsUseCase,
            deleteProductUseCase: deleteProductUseCase,
            manageAlertsUseCase: manageAlertsUseCase
        )
        
        self.alertsViewModel = AlertsViewModel(
            manageAlertsUseCase: manageAlertsUseCase,
            deleteProductUseCase: deleteProductUseCase
        )
        
        self.addProductViewModel = AddProductViewModel(
            addProductUseCase: addProductUseCase
        )
        
        // Setup notifications
        setupNotifications()
        
        // Add sample data if needed
        addSampleDataIfNeeded()
        
        // Observer les erreurs Core Data
        setupCoreDataErrorObserver()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                productListViewModel: productListViewModel,
                alertsViewModel: alertsViewModel,
                addProductViewModel: addProductViewModel
            )
            .preferredColorScheme(.light)
            .alert("Erreur de données", isPresented: $showCoreDataError) {
                Button("OK") {
                    showCoreDataError = false
                }
                if let error = coreDataError, error == .dataError(.coreDataFatalError) {
                    Button("Réessayer") {
                        Task {
                            await attemptCoreDataRecovery()
                        }
                    }
                }
            } message: {
                VStack {
                    Text(coreDataError?.errorDescription ?? "Erreur inconnue")
                    if isInMemoryMode {
                        Text("⚠️ Mode mémoire temporaire activé")
                            .font(.caption)
                    }
                }
            }
            .onChange(of: isInMemoryMode) { _, newValue in
                if newValue {
                    // Notifier l'utilisateur du mode temporaire
                    showCoreDataError = true
                }
            }
        }
    }
    
    private func setupNotifications() {
        Task {
            do {
                try await notificationService.requestPermission()
                print("✅ Notifications autorisées")
            } catch {
                print("⚠️ Erreur notifications: \(error)")
            }
        }
    }
    
    private func addSampleDataIfNeeded() {
        // Vérifier si les données de test ont déjà été ajoutées
        guard !UserDefaults.standard.bool(forKey: "hasSampleData") else { 
            print("ℹ️ Données de test déjà présentes")
            return 
        }
        
        Task {
            do {
                let existingProducts = try await searchProductsUseCase.fetchAllProducts()
                
                if existingProducts.isEmpty {
                    let sampleProducts = createSampleProducts()
                    
                    for product in sampleProducts {
                        _ = try await addProductUseCase.execute(product)
                    }
                    
                    // Marquer que les données de test ont été ajoutées
                    UserDefaults.standard.set(true, forKey: "hasSampleData")
                    print("✅ Données de test ajoutées avec succès")
                }
            } catch {
                print("⚠️ Erreur lors de l'ajout des données de test: \(error)")
            }
        }
    }
    
    private func createSampleProducts() -> [ProductModel] {
        return [
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
                name: "Carottes",
                quantity: 1.5,
                unit: "kg",
                category: .vegetables,
                location: .refrigerator,
                arrivalDate: Date().addingTimeInterval(-2 * 24 * 60 * 60),
                expirationDate: Date().addingTimeInterval(2 * 24 * 60 * 60), // Soon expired
                lotNumber: "LOT5678"
            ),
            ProductModel(
                name: "Lait",
                quantity: 1.0,
                unit: "L",
                category: .dairy,
                location: .refrigerator,
                arrivalDate: Date().addingTimeInterval(-1 * 24 * 60 * 60),
                expirationDate: Date().addingTimeInterval(10 * 24 * 60 * 60), // Fresh
                lotNumber: "LOT9012"
            ),
            ProductModel(
                name: "Poulet",
                quantity: 0.8,
                unit: "kg",
                category: .meat,
                location: .freezer,
                arrivalDate: Date().addingTimeInterval(-5 * 24 * 60 * 60),
                expirationDate: Date().addingTimeInterval(20 * 24 * 60 * 60), // Fresh
                lotNumber: "LOT3456"
            ),
            ProductModel(
                name: "Haricots verts",
                quantity: 1.0,
                unit: "boîte",
                category: .canned,
                location: .cupboard,
                arrivalDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                expirationDate: Date().addingTimeInterval(180 * 24 * 60 * 60), // Long shelf life
                lotNumber: "LOT7890"
            )
        ]
    }
    
    // MARK: - Core Data Error Handling
    private func setupCoreDataErrorObserver() {
        _ = NotificationCenter.default.addObserver(
            forName: .coreDataInitializationFailed,
            object: nil,
            queue: .main
        ) { notification in
            if let error = notification.userInfo?["error"] as? AppError {
                self.coreDataError = error
                self.showCoreDataError = true
                
                if let isFatal = notification.userInfo?["isFatal"] as? Bool, isFatal {
                    print("❌ Erreur Core Data fatale détectée")
                }
            }
        }
        
        _ = NotificationCenter.default.addObserver(
            forName: .coreDataRecovered,
            object: nil,
            queue: .main
        ) { notification in
            if let isInMemory = notification.userInfo?["isInMemory"] as? Bool {
                self.isInMemoryMode = isInMemory
                print("✅ Core Data récupéré (inMemory: \(isInMemory))")
            }
        }
        
        // Note: observers will be stored in @State property which is not ideal
        // but struct App doesn't have deinit
    }
    
    private func attemptCoreDataRecovery() async {
        do {
            try await persistenceController.attemptRecovery()
            isInMemoryMode = false
            showCoreDataError = false
            
            // Recharger les données
            await productListViewModel.loadProducts()
            await alertsViewModel.loadAlerts()
            
            print("✅ Récupération Core Data réussie")
        } catch {
            print("❌ Échec de récupération Core Data: \(error)")
            coreDataError = AppError.dataError(.coreDataError(error.localizedDescription))
            showCoreDataError = true
        }
    }
}
