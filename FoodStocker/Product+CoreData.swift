//
//  Product+CoreData.swift
//  FoodStocker
//
//  Created by TLiLi Hamdi on 24/07/2025.
//

import Foundation
import CoreData
import SwiftUI

extension Product {
    
    // Propriétés calculées pour un meilleur accès
    var displayName: String {
        return nom ?? "Produit sans nom"
    }
    
    var displayCategory: String {
        return categorie ?? "Non catégorisé"
    }
    
    var displayLocation: String {
        return emplacement ?? "Non localisé"
    }
    
    var displayUnit: String {
        return unite ?? ""
    }
    
    var displayLotNumber: String {
        return numeroLot ?? ""
    }
    
    // Calculer le statut d'expiration
    var expirationStatus: ExpirationStatus {
        guard let expirationDate = dateExpiration else { return .unknown }
        
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        
        if daysUntilExpiration < 0 {
            return .expired
        } else if daysUntilExpiration <= 3 {
            return .soonExpired
        } else {
            return .fresh
        }
    }
    
    enum ExpirationStatus {
        case fresh, soonExpired, expired, unknown
        
        var color: Color {
            switch self {
            case .fresh: return .green
            case .soonExpired: return .orange
            case .expired: return .red
            case .unknown: return .gray
            }
        }
    }
}

