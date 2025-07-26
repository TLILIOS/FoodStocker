import Foundation
@preconcurrency import CoreData

// MARK: - Core Data Product Repository Implementation
final class CoreDataProductRepository: ProductRepositoryProtocol, @unchecked Sendable {
    private let container: NSPersistentContainer
    private let viewContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    
    init(container: NSPersistentContainer) {
        self.container = container
        self.viewContext = container.viewContext
        self.backgroundContext = container.newBackgroundContext()
        
        // Configure merge policies for conflict resolution
        self.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Configure automatic merging from background to view context
        self.viewContext.automaticallyMergesChangesFromParent = true
        self.backgroundContext.automaticallyMergesChangesFromParent = true
    }
    
    func fetchProducts() async throws -> [ProductModel] {
        try await backgroundContext.perform {
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            
            do {
                let coreDataProducts = try self.backgroundContext.fetch(request)
                return coreDataProducts.compactMap { $0.toDomainModel() }
            } catch {
                throw AppError.dataError(.fetchFailed)
            }
        }
    }
    
    func addProduct(_ product: ProductModel) async throws {
        try await backgroundContext.perform {
            do {
                // Vérifier si le produit existe déjà
                let request: NSFetchRequest<Product> = Product.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", product.id as CVarArg)
                let existingProducts = try self.backgroundContext.fetch(request)
                
                if !existingProducts.isEmpty {
                    throw AppError.dataError(.coreDataError("Produit déjà existant"))
                }
                
                // Créer le nouveau produit
                let coreDataProduct = Product(context: self.backgroundContext)
                coreDataProduct.updateFromDomainModel(product)
                
                // Validation avant sauvegarde
                if self.backgroundContext.hasChanges {
                    try self.backgroundContext.save()
                    
                    // 🔧 NOTIFICATION: Forcer synchronisation vers viewContext
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        NotificationCenter.default.post(
                            name: .NSManagedObjectContextDidSave,
                            object: self.backgroundContext
                        )
                        // Notification CRUD personnalisée
                        NotificationCenter.default.post(name: .productDataChanged, object: nil)
                    }
                } else {
                    throw AppError.dataError(.saveFailed)
                }
                
            } catch let error as AppError {
                throw error
            } catch {
                // Log de l'erreur Core Data spécifique pour debug
                print("🔴 Core Data Add Error: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("🔴 Core Data Error Details: \(nsError.userInfo)")
                }
                throw AppError.dataError(.saveFailed)
            }
        }
    }
    
    func updateProduct(_ product: ProductModel) async throws {
        try await backgroundContext.perform {
            do {
                let request: NSFetchRequest<Product> = Product.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", product.id as CVarArg)
                
                let results = try self.backgroundContext.fetch(request)
                guard let coreDataProduct = results.first else {
                    throw AppError.dataError(.productNotFound)
                }
                
                // Mettre à jour avec le nouveau modèle
                coreDataProduct.updateFromDomainModel(product)
                
                // Vérifier qu'il y a vraiment des changements
                if self.backgroundContext.hasChanges {
                    try self.backgroundContext.save()
                    
                    // 🔧 NOTIFICATION: Forcer synchronisation vers viewContext
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        NotificationCenter.default.post(
                            name: .NSManagedObjectContextDidSave,
                            object: self.backgroundContext
                        )
                        // Notification CRUD personnalisée
                        NotificationCenter.default.post(name: .productDataChanged, object: nil)
                    }
                } else {
                    // Pas de changements détectés
                    print("ℹ️ Aucun changement détecté pour le produit \(product.name)")
                }
                
            } catch let error as AppError {
                throw error
            } catch {
                print("🔴 Core Data Update Error: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("🔴 Core Data Error Details: \(nsError.userInfo)")
                }
                throw AppError.dataError(.saveFailed)
            }
        }
    }
    
    func deleteProduct(withId id: UUID) async throws {
        try await backgroundContext.perform {
            do {
                let request: NSFetchRequest<Product> = Product.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                
                let results = try self.backgroundContext.fetch(request)
                guard let product = results.first else {
                    throw AppError.dataError(.productNotFound)
                }
                
                let productName = product.nom ?? "Produit inconnu"
                self.backgroundContext.delete(product)
                
                if self.backgroundContext.hasChanges {
                    try self.backgroundContext.save()
                    print("✅ Produit supprimé: \(productName)")
                    
                    // 🔧 NOTIFICATION: Forcer synchronisation vers viewContext
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        NotificationCenter.default.post(
                            name: .NSManagedObjectContextDidSave,
                            object: self.backgroundContext
                        )
                        // Notification CRUD personnalisée
                        NotificationCenter.default.post(name: .productDataChanged, object: nil)
                    }
                } else {
                    throw AppError.dataError(.deleteFailed)
                }
                
            } catch let error as AppError {
                throw error
            } catch {
                print("🔴 Core Data Delete Error: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("🔴 Core Data Error Details: \(nsError.userInfo)")
                }
                throw AppError.dataError(.deleteFailed)
            }
        }
    }
    
    func searchProducts(query: String) async throws -> [ProductModel] {
        try await backgroundContext.perform {
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            request.predicate = NSPredicate(
                format: "nom CONTAINS[cd] %@ OR categorie CONTAINS[cd] %@ OR numeroLot CONTAINS[cd] %@",
                query, query, query
            )
            
            do {
                let results = try self.backgroundContext.fetch(request)
                return results.compactMap { $0.toDomainModel() }
            } catch {
                throw AppError.dataError(.fetchFailed)
            }
        }
    }
    
    func getProductsExpiringWithin(days: Int) async throws -> [ProductModel] {
        try await backgroundContext.perform {
            let targetDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            request.predicate = NSPredicate(format: "dateExpiration <= %@ AND dateExpiration >= %@", targetDate as NSDate, Date() as NSDate)
            
            do {
                let results = try self.backgroundContext.fetch(request)
                return results.compactMap { $0.toDomainModel() }
            } catch {
                throw AppError.dataError(.fetchFailed)
            }
        }
    }
    
    func getExpiredProducts() async throws -> [ProductModel] {
        try await backgroundContext.perform {
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            request.predicate = NSPredicate(format: "dateExpiration < %@", Date() as NSDate)
            
            do {
                let results = try self.backgroundContext.fetch(request)
                return results.compactMap { $0.toDomainModel() }
            } catch {
                throw AppError.dataError(.fetchFailed)
            }
        }
    }
}

// MARK: - Core Data Product Extensions
extension Product {
    func toDomainModel() -> ProductModel? {
        guard let id = self.id,
              let nom = self.nom,
              let unite = self.unite,
              let categorie = self.categorie,
              let emplacement = self.emplacement,
              let dateArrivee = self.dateArrivee,
              let dateExpiration = self.dateExpiration,
              let numeroLot = self.numeroLot,
              let category = ProductCategory(rawValue: categorie),
              let location = ProductLocation(rawValue: emplacement) else {
            return nil
        }
        
        return ProductModel(
            id: id,
            name: nom,
            quantity: quantite,
            unit: unite,
            category: category,
            location: location,
            arrivalDate: dateArrivee,
            expirationDate: dateExpiration,
            lotNumber: numeroLot
        )
    }
    
    func updateFromDomainModel(_ model: ProductModel) {
        self.id = model.id
        self.nom = model.name
        self.quantite = model.quantity
        self.unite = model.unit
        self.categorie = model.category.rawValue
        self.emplacement = model.location.rawValue
        self.dateArrivee = model.arrivalDate
        self.dateExpiration = model.expirationDate
        self.numeroLot = model.lotNumber
    }
}