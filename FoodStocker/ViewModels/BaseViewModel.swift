//
//  BaseViewModel.swift
//  FoodStocker
//
//  Gestion centralisée des erreurs et états communs
//

import SwiftUI
import Observation
import os.log

// MARK: - Base ViewModel Protocol
protocol BaseViewModelProtocol: AnyObject {
    var error: AppError? { get }
    var isLoading: Bool { get }
    func handleError(_ error: Error)
    func clearError()
}

// MARK: - Base ViewModel Implementation
@Observable
class BaseViewModel: BaseViewModelProtocol {
    // MARK: - Common State
    private(set) var error: AppError?
    private(set) var isLoading = false {
        didSet {
            logger.debug("Loading state changed: \(self.isLoading)")
        }
    }
    
    // MARK: - Logger
    private let logger: Logger
    private let subsystem = "com.foodstocker"
    
    // MARK: - Retry Configuration
    private let maxRetryAttempts = 3
    private var retryCount = 0
    
    init(category: String = "BaseViewModel") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    // MARK: - Error Handling
    func handleError(_ error: Error) {
        // Log error avec contexte
        logger.error("🔴 Erreur: \(error.localizedDescription, privacy: .public)")
        
        // Convertir en AppError si nécessaire
        if let appError = error as? AppError {
            self.error = appError
        } else {
            self.error = AppError.unknown(error.localizedDescription)
        }
        
        // Analytics/Monitoring (future implementation)
        trackError(error)
    }
    
    func clearError() {
        error = nil
        retryCount = 0
    }
    
    // MARK: - Loading State Management
    @MainActor
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    // MARK: - Retry Logic
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void,
        shouldRetry: @escaping (Error) -> Bool = { _ in true }
    ) async {
        await setLoading(true)
        defer {
            Task { @MainActor in
                self.setLoading(false)
            }
        }
        
        for attempt in 0...maxRetryAttempts {
            do {
                let result = try await operation()
                await MainActor.run {
                    onSuccess(result)
                    self.clearError()
                    self.retryCount = 0 // Reset après succès
                }
                return // Succès - sortir de la boucle
                
            } catch {
                if shouldRetry(error) && attempt < maxRetryAttempts {
                    logger.warning("⚠️ Retry \(attempt + 1)/\(self.maxRetryAttempts) après erreur")
                    
                    // Délai exponentiel avant retry (0.5s, 1s, 2s)
                    let delay = UInt64(pow(2.0, Double(attempt)) * 0.5 * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: delay)
                    
                } else {
                    // Échec final ou erreur non-retriable
                    await MainActor.run {
                        self.retryCount = attempt
                        self.handleError(error)
                    }
                    return
                }
            }
        }
    }
    
    // MARK: - Common Operations  
    func performAsyncOperation<T>(
        _ operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void = { _ in },
        onError: @escaping (Error) -> Void = { _ in }
    ) {
        Task { @MainActor in
            // Éviter les états de loading en doublon
            guard !isLoading else {
                logger.debug("🔄 Opération déjà en cours, ignorée")
                return
            }
            
            setLoading(true)
            
            do {
                let result = try await operation()
                onSuccess(result)
                clearError()
            } catch {
                handleError(error)
                onError(error)
            }
            
            setLoading(false)
        }
    }
    
    // MARK: - Error Tracking (Placeholder for analytics)
    private func trackError(_ error: Error) {
        // Future: Intégration avec service d'analytics
        logger.debug("📊 Error tracked: \(String(describing: type(of: error)))")
    }
    
    // MARK: - Validation Helpers
    func validateNotEmpty(_ value: String?, fieldName: String) throws {
        guard let value = value, !value.isEmpty else {
            throw AppError.validationError(.emptyName)
        }
    }
    
    func validatePositiveQuantity(_ quantity: Double) throws {
        guard quantity > 0 else {
            throw AppError.validationError(.invalidQuantity)
        }
    }
    
    func validateFutureDate(_ date: Date, fieldName: String) throws {
        guard date > Date() else {
            throw AppError.validationError(.pastExpirationDate)
        }
    }
}

// MARK: - Network Retry Policy
extension BaseViewModel {
    func isRetriableError(_ error: Error) -> Bool {
        // Définir les erreurs qui méritent un retry
        if let appError = error as? AppError {
            switch appError {
            case .dataError(let dataError):
                switch dataError {
                case .fetchFailed, .saveFailed:
                    return true
                case .coreDataError, .coreDataFatalError, .productNotFound, .deleteFailed:
                    return false
                }
            case .notificationError(.schedulingFailed):
                return true
            default:
                return false
            }
        }
        
        // Erreurs réseau standard
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotConnectToHost, .networkConnectionLost:
                return true
            default:
                return false
            }
        }
        
        return false
    }
}