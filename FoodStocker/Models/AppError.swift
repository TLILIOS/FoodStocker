import Foundation

// MARK: - Centralized Error Management
enum AppError: LocalizedError, Equatable {
    case dataError(DataError)
    case validationError(ValidationError)
    case notificationError(NotificationError)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .dataError(let error):
            return error.localizedDescription
        case .validationError(let error):
            return error.localizedDescription
        case .notificationError(let error):
            return error.localizedDescription
        case .unknown(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataError(let error):
            return error.recoverySuggestion
        case .validationError(let error):
            return error.recoverySuggestion
        case .notificationError(let error):
            return error.recoverySuggestion
        case .unknown:
            return "Veuillez réessayer ou contacter le support"
        }
    }
}

// MARK: - Data Errors
enum DataError: LocalizedError, Equatable {
    case fetchFailed
    case saveFailed
    case deleteFailed
    case coreDataError(String)
    case coreDataFatalError
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Impossible de charger les données"
        case .saveFailed:
            return "Impossible de sauvegarder"
        case .deleteFailed:
            return "Impossible de supprimer"
        case .coreDataError(let message):
            return "Erreur de base de données: \(message)"
        case .coreDataFatalError:
            return "Erreur critique de la base de données. Les données sont temporairement stockées en mémoire."
        case .productNotFound:
            return "Produit introuvable"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Vérifiez votre connexion et réessayez"
        case .saveFailed:
            return "Vérifiez les données saisies et réessayez"
        case .deleteFailed:
            return "Réessayez la suppression"
        case .coreDataError:
            return "Redémarrez l'application"
        case .coreDataFatalError:
            return "Les données seront perdues au redémarrage. Contactez le support si le problème persiste."
        case .productNotFound:
            return "Actualisez la liste des produits"
        }
    }
}

// MARK: - Validation Errors
enum ValidationError: LocalizedError, Equatable {
    case emptyName
    case invalidQuantity
    case pastExpirationDate
    case emptyLotNumber
    case invalidCategory
    case invalidLocation
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Le nom du produit est requis"
        case .invalidQuantity:
            return "La quantité doit être supérieure à 0"
        case .pastExpirationDate:
            return "La date d'expiration ne peut pas être dans le passé"
        case .emptyLotNumber:
            return "Le numéro de lot est requis"
        case .invalidCategory:
            return "Catégorie invalide"
        case .invalidLocation:
            return "Emplacement invalide"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyName:
            return "Saisissez un nom pour le produit"
        case .invalidQuantity:
            return "Saisissez une quantité valide"
        case .pastExpirationDate:
            return "Choisissez une date future"
        case .emptyLotNumber:
            return "Saisissez ou scannez un numéro de lot"
        case .invalidCategory:
            return "Sélectionnez une catégorie valide"
        case .invalidLocation:
            return "Sélectionnez un emplacement valide"
        }
    }
}

// MARK: - Notification Errors
enum NotificationError: LocalizedError, Equatable {
    case permissionDenied
    case schedulingFailed
    case invalidContent
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notifications non autorisées"
        case .schedulingFailed:
            return "Impossible de programmer la notification"
        case .invalidContent:
            return "Contenu de notification invalide"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Activez les notifications dans les Réglages"
        case .schedulingFailed:
            return "Réessayez plus tard"
        case .invalidContent:
            return "Vérifiez les données du produit"
        }
    }
}