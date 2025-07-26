import Foundation
import CoreData
import Observation
import os.log

// MARK: - Custom Notifications for CRUD Operations
extension Notification.Name {
    static let productDataChanged = Notification.Name("productDataChanged")
}

// MARK: - Product List View Model
@Observable
final class ProductListViewModel: BaseViewModel {
    
    // MARK: - Public Properties
    private(set) var products: [ProductModel] = []
    private(set) var filteredProducts: [ProductModel] = []
    
    var searchText = "" {
        didSet {
            filterAndSortProducts()
        }
    }
    
    var sortOption: ProductSortOption = .name {
        didSet {
            filterAndSortProducts()
        }
    }
    
    var alertProductsCount: Int {
        products.filter { $0.isSoonExpired || $0.isExpired }.count
    }
    
    var expiredProductsCount: Int {
        products.filter { $0.isExpired }.count
    }
    
    var soonExpiredProductsCount: Int {
        products.filter { $0.isSoonExpired }.count
    }
    
    // MARK: - Private Properties - Use Cases
    private let searchProductsUseCase: SearchProductsUseCaseProtocol
    private let deleteProductUseCase: DeleteProductUseCaseProtocol
    private let manageAlertsUseCase: ManageExpirationAlertsUseCaseProtocol
    
    // MARK: - Refresh Protection
    private var isRefreshing = false
    
    // MARK: - Initialization
    init(
        searchProductsUseCase: SearchProductsUseCaseProtocol,
        deleteProductUseCase: DeleteProductUseCaseProtocol,
        manageAlertsUseCase: ManageExpirationAlertsUseCaseProtocol
    ) {
        self.searchProductsUseCase = searchProductsUseCase
        self.deleteProductUseCase = deleteProductUseCase
        self.manageAlertsUseCase = manageAlertsUseCase
        super.init(category: "ProductListViewModel")
        
        // 🔧 ÉCOUTER: Notifications de changement Core Data
        setupCoreDataNotifications()
    }
    
    // MARK: - Public Methods
    @MainActor
    func loadProducts() async {
        await executeWithRetry(
            operation: { [weak self] in
                guard let self = self else { throw AppError.unknown("Self deallocated") }
                let fetchedProducts = try await self.searchProductsUseCase.fetchAllProducts()
                await self.scheduleNotificationsForProducts(fetchedProducts)
                return fetchedProducts
            },
            onSuccess: { [weak self] (fetchedProducts: [ProductModel]) in
                self?.products = fetchedProducts
                self?.filterAndSortProducts()
                FoodStockerLogger.logSuccess("Produits chargés: \(fetchedProducts.count)", category: .viewModel)
            },
            shouldRetry: isRetriableError
        )
    }
    
    @MainActor
    func refreshProducts() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await loadProducts()
    }
    
    @MainActor
    func deleteProduct(_ product: ProductModel) async {
        await executeWithRetry(
            operation: { [weak self] in
                guard let self = self else { throw AppError.unknown("Self deallocated") }
                try await self.deleteProductUseCase.executeWithProduct(product)
            },
            onSuccess: { [weak self] _ in
                Task {
                    await self?.loadProducts()
                }
            },
            shouldRetry: isRetriableError
        )
    }
    
    @MainActor
    func searchProducts(query: String) async {
        searchText = query
        
        if query.isEmpty {
            filteredProducts = sortOption.sort(products)
        } else {
            await executeWithRetry(
                operation: { [weak self] in
                    guard let self = self else { throw AppError.unknown("Self deallocated") }
                    return try await self.searchProductsUseCase.searchProducts(query: query, sortOption: self.sortOption)
                },
                onSuccess: { [weak self] searchResults in
                    self?.filteredProducts = searchResults
                },
                shouldRetry: isRetriableError
            )
        }
    }
    
    // clearError() héritée de BaseViewModel
    
    func getProduct(by id: UUID) -> ProductModel? {
        products.first { $0.id == id }
    }
    
    // MARK: - Private Methods
    private func filterAndSortProducts() {
        let filtered: [ProductModel]
        
        if searchText.isEmpty {
            filtered = products
        } else {
            filtered = products.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                product.location.rawValue.localizedCaseInsensitiveContains(searchText) ||
                product.lotNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredProducts = sortOption.sort(filtered)
    }
    
    @MainActor
    private func scheduleNotificationsForProducts(_ products: [ProductModel]) async {
        do {
            try await manageAlertsUseCase.scheduleNotificationsForUpcomingProducts(products)
        } catch {
            // Silent failure for notifications - don't interrupt main flow
            FoodStockerLogger.logError(error, category: .viewModel, context: "Failed to schedule notifications")
        }
    }
    
    // MARK: - Core Data Notifications
    private func setupCoreDataNotifications() {
        // Écouter les notifications de sauvegarde du contexte d'arrière-plan
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Vérifier que c'est bien une notification d'un contexte d'arrière-plan
            if let context = notification.object as? NSManagedObjectContext,
               context.concurrencyType == .privateQueueConcurrencyType {
                
                print("🔄 Notification Core Data détectée - rafraîchissement UI")
                
                // Forcer le rafraîchissement de la liste
                Task { @MainActor in
                    await self?.refreshProducts()
                }
            }
        }
        
        // Écouter aussi les notifications CRUD personnalisées
        NotificationCenter.default.addObserver(
            forName: .productDataChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔄 Notification CRUD détectée - rafraîchissement UI")
            Task { @MainActor in
                await self?.refreshProducts()
            }
        }
    }
    
    // Nettoyage des observers
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Mock View Model for Previews
extension ProductListViewModel {
    static func mock() -> ProductListViewModel {
        return ProductListViewModel(
            searchProductsUseCase: MockSearchProductsUseCase(),
            deleteProductUseCase: MockDeleteProductUseCase(),
            manageAlertsUseCase: MockManageExpirationAlertsUseCase()
        )
    }
}

