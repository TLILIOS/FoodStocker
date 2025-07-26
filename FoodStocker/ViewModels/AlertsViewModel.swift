import Foundation
import Observation
import os.log
import SwiftUI

// MARK: - Alerts View Model
@Observable
final class AlertsViewModel: BaseViewModel {
    
    // MARK: - Public Properties
    private(set) var expiredProducts: [ProductModel] = []
    private(set) var soonExpiredProducts: [ProductModel] = []
    
    var totalAlertsCount: Int {
        expiredProducts.count + soonExpiredProducts.count
    }
    
    var hasAlerts: Bool {
        totalAlertsCount > 0
    }
    
    // MARK: - Private Properties - Use Cases
    private let manageAlertsUseCase: ManageExpirationAlertsUseCaseProtocol
    private let deleteProductUseCase: DeleteProductUseCaseProtocol
    
    // MARK: - Initialization
    init(
        manageAlertsUseCase: ManageExpirationAlertsUseCaseProtocol,
        deleteProductUseCase: DeleteProductUseCaseProtocol
    ) {
        self.manageAlertsUseCase = manageAlertsUseCase
        self.deleteProductUseCase = deleteProductUseCase
        super.init(category: "AlertsViewModel")
    }
    
    // MARK: - Public Methods
    @MainActor
    func loadAlerts() async {
        await executeWithRetry(
            operation: { [weak self] in
                guard let self = self else { throw AppError.unknown("Self deallocated") }
                return try await self.manageAlertsUseCase.loadAlerts()
            },
            onSuccess: { [weak self] alertsResult in
                self?.expiredProducts = alertsResult.expiredProducts
                self?.soonExpiredProducts = alertsResult.soonExpiredProducts
                
                FoodStockerLogger.logInfo(
                    "Alertes chargées - Total: \(alertsResult.totalCount)",
                    category: .viewModel
                )
            },
            shouldRetry: isRetriableError
        )
    }
    
    @MainActor
    func refreshAlerts() async {
        await loadAlerts()
    }
    
    @MainActor
    func deleteProduct(_ product: ProductModel) async {
        await executeWithRetry(
            operation: { [weak self] in
                guard let self = self else { throw AppError.unknown("Self deallocated") }
                try await self.deleteProductUseCase.executeWithProduct(product)
            },
            onSuccess: { [weak self] _ in
                FoodStockerLogger.logSuccess("Produit supprimé depuis alertes: \(product.name)", category: .viewModel)
                Task { await self?.loadAlerts() }
            },
            shouldRetry: isRetriableError
        )
    }
    
    @MainActor
    func dismissProduct(_ product: ProductModel) async {
        // Remove from local arrays (temporary dismissal)
        expiredProducts.removeAll { $0.id == product.id }
        soonExpiredProducts.removeAll { $0.id == product.id }
        
        // Remove notification using Use Case
        do {
            try await manageAlertsUseCase.dismissAlert(for: product)
            FoodStockerLogger.logInfo("Alerte supprimée pour: \(product.name)", category: .viewModel)
        } catch {
            handleError(error)
        }
    }
    
    // clearError() héritée de BaseViewModel
    
    func getAlertTypeForProduct(_ product: ProductModel) -> AlertType {
        if expiredProducts.contains(where: { $0.id == product.id }) {
            return .expired
        } else if soonExpiredProducts.contains(where: { $0.id == product.id }) {
            return .soonExpired
        } else {
            return .unknown
        }
    }
}

// MARK: - Alert Type
enum AlertType {
    case expired
    case soonExpired
    case unknown
    
    var title: String {
        switch self {
        case .expired:
            return "Produits expirés"
        case .soonExpired:
            return "Expiration proche"
        case .unknown:
            return "Autres alertes"
        }
    }
    
    var icon: String {
        switch self {
        case .expired:
            return "exclamationmark.triangle.fill"
        case .soonExpired:
            return "clock.badge.exclamationmark.fill"
        case .unknown:
            return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .expired:
            return .red
        case .soonExpired:
            return .orange
        case .unknown:
            return .gray
        }
    }
    
    var priority: Int {
        switch self {
        case .expired:
            return 0
        case .soonExpired:
            return 1
        case .unknown:
            return 2
        }
    }
}

// MARK: - Mock View Model for Previews
extension AlertsViewModel {
    static func mock() -> AlertsViewModel {
        return AlertsViewModel(
            manageAlertsUseCase: MockManageExpirationAlertsUseCase(),
            deleteProductUseCase: MockDeleteProductUseCase()
        )
    }
}