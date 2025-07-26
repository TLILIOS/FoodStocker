import SwiftUI

struct ProductListView: View {
    @State private var viewModel: ProductListViewModel
    
    init(viewModel: ProductListViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arrière-plan avec vos couleurs
                Color.AppGradients.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Chargement des produits...")
                        .accessibilityLabel("Chargement en cours")
                } else if viewModel.filteredProducts.isEmpty {
                    EmptyStateView()
                } else {
                    ProductListContent(viewModel: viewModel)
                }
            }
            .navigationTitle("🏪 Stocks")
            .navigationBarTitleDisplayMode(.large)
            .accessibilityLabel("Liste des stocks alimentaires")
            .toolbarBackground(Color.AppGradients.primary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $viewModel.searchText, prompt: "Rechercher un produit")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SortMenuView(sortOption: $viewModel.sortOption)
                }
            }
            .alert("Erreur", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
        .task {
            await viewModel.loadProducts()
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "cube.box")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .accessibilityLabel("Aucun produit")
            }
            .scaleEffect(animateIcon ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
            
            VStack(spacing: 12) {
                Text("Aucun produit")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Ajoutez votre premier produit en appuyant sur l'onglet 'Ajouter'")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityHint("Double-tapez sur l'onglet Ajouter pour créer un nouveau produit")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animateIcon = true
        }
    }
}

// MARK: - Product List Content
struct ProductListContent: View {
    @Bindable var viewModel: ProductListViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.filteredProducts.enumerated()), id: \.element.id) { index, product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        ModernProductRowView(product: product)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: viewModel.filteredProducts.count)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteProduct(product)
                            }
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .refreshable {
            await viewModel.refreshProducts()
        }
        .accessibilityLabel("Liste de \(viewModel.filteredProducts.count) produits")
    }
}

// MARK: - Sort Menu View
struct SortMenuView: View {
    @Binding var sortOption: ProductSortOption
    
    var body: some View {
        Menu {
            Picker("Trier par", selection: $sortOption) {
                ForEach(ProductSortOption.allCases, id: \.self) { option in
                    Label(option.displayName, systemImage: option.icon)
                        .tag(option)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.AppGradients.accent)
            }
        }
        .accessibilityLabel("Trier les produits")
        .accessibilityValue("Tri actuel: \(sortOption.displayName)")
    }
}

// MARK: - Modern Product Row View
struct ModernProductRowView: View {
    let product: ProductModel
    
    private var statusGradient: LinearGradient {
        switch product.expirationStatus {
        case .expired:
            return Color.ExpirationColors.expired
        case .soonExpired:
            return Color.ExpirationColors.soonExpired
        case .fresh:
            return Color.ExpirationColors.fresh
        case .unknown:
            return Color.AppGradients.secondary
        }
    }
    
    private var statusDescription: String {
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Indicator
            ZStack {
                Circle()
                    .fill(statusGradient)
                    .frame(width: 12, height: 12)
                
                Circle()
                    .stroke(statusGradient.opacity(0.3), lineWidth: 8)
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel(statusDescription)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Category Icon
                    Image(systemName: product.category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(statusGradient)
                        .frame(width: 20)
                        .accessibilityLabel("Catégorie: \(product.category.rawValue)")
                    
                    Text(product.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .accessibilityLabel("Produit: \(product.name)")
                    
                    Spacer()
                    
                    // Quantity Badge
                    Text(product.formattedQuantity)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .accessibilityLabel("Quantité: \(product.formattedQuantity)")
                }
                
                HStack(spacing: 12) {
                    Label(product.category.rawValue, systemImage: product.category.icon)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    
                    Label(product.expirationDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(statusGradient)
                        .accessibilityLabel("Expire le \(product.expirationDate.formatted(date: .complete, time: .omitted))")
                }
            }
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(product.location.rawValue)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue.opacity(0.3), lineWidth: 1)
                    )
                    .accessibilityLabel("Emplacement: \(product.location.rawValue)")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.name), \(product.category.rawValue), \(product.formattedQuantity), \(statusDescription)")
        .accessibilityHint("Double-tapez pour voir les détails du produit")
    }
}

#Preview {
    ProductListView(viewModel: ProductListViewModel.mock())
}
