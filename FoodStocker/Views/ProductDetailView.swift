import SwiftUI

struct ProductDetailView: View {
    let product: ProductModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with product status
                ProductHeaderView(product: product)
                
                // Product Information
                ProductInfoSection(product: product)
                
                // Expiration Information
                ExpirationInfoSection(product: product)
                
                // Actions
                ActionButtonsView(product: product)
            }
            .padding()
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.large)
        .background(
            ZStack {
                // Arrière-plan principal - Color1 et Color2 DOMINANTES
                LinearGradient(
                    colors: [
                        Color.appColor1.opacity(0.6),
                        Color.appColor2.opacity(0.5),
                        Color.appColor1.opacity(0.4),
                        Color.appColor2.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Couche d'accent avec Color2 visible
                RadialGradient(
                    colors: [
                        Color.appColor2.opacity(0.3),
                        Color.appColor1.opacity(0.2),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 30,
                    endRadius: 250
                )
            }
            .ignoresSafeArea()
        )
    }
}

// MARK: - Product Header View
struct ProductHeaderView: View {
    let product: ProductModel
    
    private var statusGradient: LinearGradient {
        switch product.expirationStatus {
        case .expired:
            return LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .soonExpired:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .fresh:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .unknown:
            return LinearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Product icon
            ZStack {
                Circle()
                    .fill(statusGradient.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: product.category.icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(statusGradient)
            }
            
            // Product name and quantity
            Text(product.name)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            
            Text(product.formattedQuantity)
                .font(.title2.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.name), \(product.formattedQuantity)")
    }
}

// MARK: - Product Info Section
struct ProductInfoSection: View {
    let product: ProductModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Informations")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                InfoCard(
                    title: "Catégorie",
                    value: product.category.rawValue,
                    icon: product.category.icon,
                    color: .blue
                )
                
                InfoCard(
                    title: "Emplacement",
                    value: product.location.rawValue,
                    icon: product.location.icon,
                    color: .purple
                )
                
                InfoCard(
                    title: "Arrivée",
                    value: product.arrivalDate.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar.badge.plus",
                    color: .green
                )
                
                InfoCard(
                    title: "Lot",
                    value: product.lotNumber,
                    icon: "barcode",
                    color: .orange
                )
            }
        }
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Expiration Info Section
struct ExpirationInfoSection: View {
    let product: ProductModel
    
    private var statusColor: Color {
        switch product.expirationStatus {
        case .expired: return .red
        case .soonExpired: return .orange
        case .fresh: return .green
        case .unknown: return .gray
        }
    }
    
    private var statusText: String {
        switch product.expirationStatus {
        case .expired(let days):
            return "Expiré depuis \(days) jour\(days > 1 ? "s" : "")"
        case .soonExpired(let days):
            return "Expire dans \(days) jour\(days > 1 ? "s" : "")"
        case .fresh:
            return "Produit frais"
        case .unknown:
            return "Statut inconnu"
        }
    }
    
    private var statusIcon: String {
        switch product.expirationStatus {
        case .expired: return "exclamationmark.triangle.fill"
        case .soonExpired: return "clock.badge.exclamationmark.fill"
        case .fresh: return "checkmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("État du produit")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                        .font(.title2)
                    
                    Text(statusText)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(statusColor)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Date d'expiration:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(product.expirationDate.formatted(date: .complete, time: .omitted))
                        .font(.subheadline.weight(.medium))
                }
            }
            .padding()
            .background(statusColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("État: \(statusText). Expire le \(product.expirationDate.formatted(date: .complete, time: .omitted))")
    }
}

// MARK: - Action Buttons View
struct ActionButtonsView: View {
    let product: ProductModel
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    @State private var isDeleting = false
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .success
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
            Button(action: {
                showingEditView = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Modifier")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.white)
            }
            .accessibilityLabel("Modifier le produit")
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    if isDeleting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "trash")
                    }
                    Text(isDeleting ? "Suppression..." : "Supprimer")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red, in: RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.white)
            }
            .disabled(isDeleting)
            .accessibilityLabel("Supprimer le produit")
        }
        .alert("Supprimer le produit", isPresented: $showingDeleteAlert) {
            Button("Supprimer", role: .destructive) {
                Task {
                    await deleteProduct()
                }
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer \(product.name) ? Cette action est irréversible.")
        }
        .sheet(isPresented: $showingEditView) {
            EditProductView(
                product: product,
                viewModel: EditProductViewModel(
                    product: product,
                    updateProductUseCase: UpdateProductUseCase(
                        productRepository: CoreDataProductRepository(container: PersistenceController.shared.container),
                        notificationService: UserNotificationService(),
                        addProductUseCase: AddProductUseCase(
                            productRepository: CoreDataProductRepository(container: PersistenceController.shared.container),
                            notificationService: UserNotificationService()
                        )
                    )
                )
            )
        }
            
            // Toast overlay
            if showingToast {
                VStack {
                    Spacer()
                    ToastView(message: toastMessage, type: toastType)
                        .padding(.bottom, 100)
                }
                .animation(.easeInOut(duration: 0.3), value: showingToast)
            }
        }
    }
    
    // MARK: - Delete Product Function
    @MainActor
    private func deleteProduct() async {
        isDeleting = true
        
        do {
            let deleteUseCase = DeleteProductUseCase(
                productRepository: CoreDataProductRepository(container: PersistenceController.shared.container),
                notificationService: UserNotificationService()
            )
            
            try await deleteUseCase.executeWithProduct(product)
            
            // Show success toast
            toastMessage = "Produit supprimé avec succès"
            toastType = .success
            showingToast = true
            
            // Auto-dismiss toast and navigate back
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
            
        } catch {
            // Handle error - show error toast and log it
            FoodStockerLogger.logError(error, category: .viewModel)
            
            toastMessage = "Erreur lors de la suppression"
            toastType = .error
            showingToast = true
            
            // Auto-dismiss error toast
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showingToast = false
            }
        }
        
        isDeleting = false
    }
}

#Preview {
    NavigationView {
        ProductDetailView(
            product: ProductModel(
                name: "Pommes",
                quantity: 2.5,
                unit: "kg",
                category: .fruits,
                location: .pantry,
                arrivalDate: Date().addingTimeInterval(-3 * 24 * 60 * 60),
                expirationDate: Date().addingTimeInterval(2 * 24 * 60 * 60),
                lotNumber: "LOT1234"
            )
        )
    }
}