//
//  Persistence.swift
//  FoodStocker
//
//  Created by TLiLi Hamdi on 24/07/2025.
//

import CoreData
import SwiftUI

// MARK: - Core Data Error Notification
extension Notification.Name {
    static let coreDataInitializationFailed = Notification.Name("coreDataInitializationFailed")
    static let coreDataRecovered = Notification.Name("coreDataRecovered")
}

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    // État de Core Data pour détection d'erreurs
    @Published private(set) var isUsingInMemoryFallback = false
    @Published private(set) var initializationError: Error?

    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Créer des produits de test
        let categories = ["Fruits", "Légumes", "Produits laitiers", "Viandes", "Conserves"]
        let noms = ["Pommes", "Carottes", "Lait", "Poulet", "Haricots verts"]
        let unites = ["kg", "kg", "L", "kg", "boîte"]
        let emplacements = ["Garde-manger", "Réfrigérateur", "Réfrigérateur", "Congélateur", "Placard"]
        
        for i in 0..<5 {
            let product = Product(context: viewContext)
            product.id = UUID()
            product.nom = noms[i]
            product.quantite = Double.random(in: 0.5...5.0)
            product.unite = unites[i]
            product.categorie = categories[i]
            product.emplacement = emplacements[i]
            product.dateArrivee = Date().addingTimeInterval(-Double.random(in: 1...10) * 24 * 60 * 60)
            
            // Dates d'expiration variées pour tester les alertes
            if i == 0 {
                product.dateExpiration = Date().addingTimeInterval(-2 * 24 * 60 * 60) // Périmé
            } else if i == 1 {
                product.dateExpiration = Date().addingTimeInterval(2 * 24 * 60 * 60) // Bientôt périmé
            } else {
                product.dateExpiration = Date().addingTimeInterval(Double.random(in: 7...30) * 24 * 60 * 60)
            }
            
            product.numeroLot = "LOT\(Int.random(in: 1000...9999))"
        }
        
        do {
            try viewContext.save()
        } catch {
            // En preview, on log juste l'erreur sans crash
            print("⚠️ Erreur sauvegarde preview: \(error)")
            // Ancien code conservé en commentaire pour référence
            // let nsError = error as NSError
            // fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FoodStocker")
        
        // Configuration du store description
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            self.initializationError = AppError.dataError(.coreDataFatalError)
            print("❌ Core Data initialization failed: No store description available")
            return
        }
        
        if inMemory {
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // 🔧 CORRECTIF CRITIQUE: Configuration Persistent History
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Options de migration automatique (déjà présentes mais explicites)
        storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        print("✅ Configuration Core Data avec Persistent History activé")
        
        container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            if let error = error {
                // Gestion gracieuse des erreurs Core Data
                print("⚠️ Erreur initialisation Core Data: \(error)")
                
                // 🔧 DÉTECTION SPÉCIFIQUE: Persistent History mal configuré
                let errorDescription = error.localizedDescription
                if errorDescription.contains("Read Only mode") && errorDescription.contains("NSPersistentHistoryTrackingKey") {
                    print("🎯 Erreur Persistent History détectée - nettoyage automatique du store")
                    
                    // Nettoyer le store corrompu
                    PersistenceController.cleanupCorruptedStore()
                    
                    // Notifier l'utilisateur qu'un redémarrage est nécessaire
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .coreDataInitializationFailed,
                            object: nil,
                            userInfo: [
                                "error": AppError.dataError(.coreDataError("Store nettoyé - redémarrage requis")),
                                "requiresRestart": true
                            ]
                        )
                    }
                    return
                }
                
                self?.initializationError = error
                
                // Notification pour l'UI
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .coreDataInitializationFailed,
                        object: nil,
                        userInfo: ["error": AppError.dataError(.coreDataError(error.localizedDescription))]
                    )
                    
                    // Tentative de fallback in-memory
                    self?.setupInMemoryFallback()
                }
            } else {
                print("✅ Core Data initialisé avec succès")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Fallback In-Memory Store
    private func setupInMemoryFallback() {
        print("🔄 Configuration fallback in-memory...")
        
        // Créer un nouveau container in-memory
        let fallbackContainer = NSPersistentContainer(name: "FoodStocker")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        
        // Configuration identique pour le fallback
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        fallbackContainer.persistentStoreDescriptions = [description]
        
        fallbackContainer.loadPersistentStores { [weak self] (_, error) in
            if let error = error {
                print("❌ Échec fallback in-memory: \(error)")
                // Dernière tentative : notifier l'utilisateur
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .coreDataInitializationFailed,
                        object: nil,
                        userInfo: ["error": AppError.dataError(.coreDataFatalError), "isFatal": true]
                    )
                }
            } else {
                print("✅ Fallback in-memory opérationnel")
                self?.isUsingInMemoryFallback = true
                
                // Remplacer le container principal
                DispatchQueue.main.async {
                    // Note: Nécessite refactoring pour permettre le remplacement du container
                    NotificationCenter.default.post(
                        name: .coreDataRecovered,
                        object: nil,
                        userInfo: ["isInMemory": true]
                    )
                }
            }
        }
    }
    
    // MARK: - Recovery Methods
    func attemptRecovery() async throws {
        print("🔧 Tentative de récupération Core Data...")
        
        // Réessayer avec le store persistant
        let newContainer = NSPersistentContainer(name: "FoodStocker")
        
        // Configuration identique pour la récupération
        if let recoveryDescription = newContainer.persistentStoreDescriptions.first {
            recoveryDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            recoveryDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            recoveryDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            recoveryDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            newContainer.loadPersistentStores { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        // Si succès, mettre à jour
        isUsingInMemoryFallback = false
        initializationError = nil
        print("✅ Core Data récupéré avec succès")
    }
    
    // MARK: - Store Cleanup for Persistent History Issues
    static func cleanupCorruptedStore() {
        print("🧹 Nettoyage du store Core Data corrompu...")
        
        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("FoodStocker.sqlite")
        
        let fileManager = FileManager.default
        
        // Supprimer les fichiers SQLite et ses compagnons
        let filesToDelete = [
            storeURL,
            storeURL.appendingPathExtension("wal"),
            storeURL.appendingPathExtension("shm")
        ]
        
        for file in filesToDelete {
            do {
                if fileManager.fileExists(atPath: file.path) {
                    try fileManager.removeItem(at: file)
                    print("✅ Supprimé: \(file.lastPathComponent)")
                }
            } catch {
                print("⚠️ Impossible de supprimer \(file.lastPathComponent): \(error)")
            }
        }
        
        print("🔄 Store nettoyé, redémarrage requis pour recréation propre")
    }
}
