import SwiftUI

struct AlertsView: View {
    @State private var viewModel: AlertsViewModel
    @State private var showExpiredOnly = false
    
    init(viewModel: AlertsViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient avec vos couleurs intensifiées
                Color.AppGradients.backgroundIntense
                    .ignoresSafeArea()
                    .hueRotation(.degrees(10))
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: true)
                
                if viewModel.isLoading {
                    ProgressView("Chargement des alertes...")
                        .accessibilityLabel("Chargement en cours")
                } else if !viewModel.hasAlerts {
                    EmptyAlertsView()
                } else {
                    AlertsContent(viewModel: viewModel, showExpiredOnly: $showExpiredOnly)
                }
            }
            .navigationTitle("⚠️ Alertes")
            .navigationBarTitleDisplayMode(.large)
            .accessibilityLabel("Alertes d'expiration")
            .toolbarBackground(Color.AppGradients.primary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Actualiser") {
                        Task {
                            await viewModel.refreshAlerts()
                        }
                    }
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
            await viewModel.loadAlerts()
        }
    }
}

// MARK: - Empty Alerts View
struct EmptyAlertsView: View {
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(Color.AppGradients.success.opacity(0.3))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(Color.AppGradients.success)
                    .accessibilityLabel("Aucune alerte")
            }
            .scaleEffect(animateIcon ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
            
            VStack(spacing: 12) {
                Text("Aucune alerte")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.AppGradients.primary)
                
                Text("Tous vos produits sont encore frais !")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animateIcon = true
        }
    }
}

// MARK: - Alerts Content
struct AlertsContent: View {
    @Bindable var viewModel: AlertsViewModel
    @Binding var showExpiredOnly: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Statistics
                AlertsStatsView(viewModel: viewModel)
                
                // Filter Toggle
                Toggle("Afficher seulement les produits expirés", isOn: $showExpiredOnly)
                    .padding(.horizontal)
                
                // Expired Products Section
                if !viewModel.expiredProducts.isEmpty && !showExpiredOnly {
                    AlertsSectionView(
                        title: "Produits expirés",
                        products: viewModel.expiredProducts,
                        alertType: .expired,
                        viewModel: viewModel
                    )
                }
                
                // Soon Expired Products Section  
                if !viewModel.soonExpiredProducts.isEmpty && !showExpiredOnly {
                    AlertsSectionView(
                        title: "Expiration proche",
                        products: viewModel.soonExpiredProducts,
                        alertType: .soonExpired,
                        viewModel: viewModel
                    )
                }
                
                // Combined view when filtering
                if showExpiredOnly {
                    AlertsSectionView(
                        title: "Produits expirés",
                        products: viewModel.expiredProducts,
                        alertType: .expired,
                        viewModel: viewModel
                    )
                }
            }
            .padding(.top)
        }
        .refreshable {
            await viewModel.refreshAlerts()
        }
    }
}

// MARK: - Alerts Stats View
struct AlertsStatsView: View {
    let viewModel: AlertsViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Expirés",
                count: viewModel.expiredProducts.count,
                color: .red,
                icon: "exclamationmark.triangle.fill"
            )
            
            StatCard(
                title: "Bientôt expirés",
                count: viewModel.soonExpiredProducts.count,
                color: .orange,
                icon: "clock.badge.exclamationmark.fill"
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title.weight(.bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(title)")
    }
}

// MARK: - Alerts Section View
struct AlertsSectionView: View {
    let title: String
    let products: [ProductModel]
    let alertType: AlertType
    let viewModel: AlertsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: alertType.icon)
                    .foregroundColor(alertType.color)
                
                Text(title)
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                Text("\(products.count)")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(alertType.color.opacity(0.2), in: Capsule())
            }
            .padding(.horizontal)
            
            ForEach(products) { product in
                AlertProductRow(product: product, alertType: alertType, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Alert Product Row
struct AlertProductRow: View {
    let product: ProductModel
    let alertType: AlertType
    let viewModel: AlertsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(alertType.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline.weight(.medium))
                
                Text("Expire le \(product.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button("Ignorer") {
                    Task {
                        await viewModel.dismissProduct(product)
                    }
                }
                
                Button("Supprimer", role: .destructive) {
                    Task {
                        await viewModel.deleteProduct(product)
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.name) expire le \(product.expirationDate.formatted(date: .complete, time: .omitted))")
    }
}

#Preview {
    AlertsView(viewModel: AlertsViewModel.mock())
}