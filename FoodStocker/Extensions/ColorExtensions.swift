import SwiftUI

// MARK: - App Color System
extension Color {
    // Couleurs personnalisées depuis Assets
    static let appColor1 = Color("Color1")
    static let appColor2 = Color("Color2") 
    static let appColor3 = Color("Color3")
    
    // Dégradés de base avec les couleurs de l'app
    struct AppGradients {
        static let primary = LinearGradient(
            colors: [.appColor1, .appColor2],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let secondary = LinearGradient(
            colors: [.appColor2, .appColor1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accent = LinearGradient(
            colors: [.appColor1, .appColor2],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let background = LinearGradient(
            colors: [
                .appColor1.opacity(0.7),
                .appColor2.opacity(0.6),
                .appColor1.opacity(0.5),
                .appColor2.opacity(0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let backgroundIntense = LinearGradient(
            colors: [
                .appColor1.opacity(0.8),
                .appColor2.opacity(0.7),
                .appColor1.opacity(0.6),
                .appColor2.opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardBackground = LinearGradient(
            colors: [
                .appColor1.opacity(0.05),
                .appColor2.opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Dégradés spécialisés par fonction
        static let success = LinearGradient(
            colors: [.appColor2, .appColor1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warning = LinearGradient(
            colors: [.appColor1, .appColor2],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let error = LinearGradient(
            colors: [.pink, .appColor1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let info = LinearGradient(
            colors: [.appColor2, .appColor1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Couleurs pour les différents états d'expiration
    struct ExpirationColors {
        static let fresh = LinearGradient(
            colors: [.appColor2, .appColor1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let soonExpired = LinearGradient(
            colors: [.appColor1, .yellow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let expired = LinearGradient(
            colors: [.pink, .appColor1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Couleurs pour les catégories
    struct CategoryColors {
        static let fruits = LinearGradient(
            colors: [.appColor2, .appColor1],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let vegetables = LinearGradient(
            colors: [.appColor1, .appColor2],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let dairy = LinearGradient(
            colors: [.appColor2, .appColor1],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let meat = LinearGradient(
            colors: [.appColor1, .pink.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let other = LinearGradient(
            colors: [.appColor2, .appColor1],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}