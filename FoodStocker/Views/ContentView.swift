//
//  ContentView.swift
//  FoodStocker
//
//  Created by TLiLi Hamdi on 24/07/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var animateTab = false
    
    // MARK: - Dependencies
    private let productListViewModel: ProductListViewModel
    private let alertsViewModel: AlertsViewModel
    private let addProductViewModel: AddProductViewModel
    
    init(
        productListViewModel: ProductListViewModel,
        alertsViewModel: AlertsViewModel,
        addProductViewModel: AddProductViewModel
    ) {
        self.productListViewModel = productListViewModel
        self.alertsViewModel = alertsViewModel
        self.addProductViewModel = addProductViewModel
    }
    
    var body: some View {
        ZStack {
            // Dégradé d'arrière-plan principal - Color1 et Color2 DOMINANTES
            LinearGradient(
                colors: [
                    Color.appColor1.opacity(0.8),
                    Color.appColor2.opacity(0.7),
                    Color.appColor1.opacity(0.6),
                    Color.appColor2.opacity(0.5),
                    Color.appColor1.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .hueRotation(.degrees(animateTab ? 45 : 0))
            .scaleEffect(animateTab ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateTab)
            
            // Superposition pour renforcer Color1 et Color2
            RadialGradient(
                colors: [
                    Color.appColor1.opacity(0.3),
                    Color.appColor2.opacity(0.2),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .blendMode(.overlay)
            
            TabView(selection: $selectedTab) {
                ProductListView(viewModel: productListViewModel)
                    .tabItem {
                        StocksTabLabel(isSelected: selectedTab == 0)
                    }
                    .tag(0)
                    .accessibilityLabel("Onglet Stocks")
                    .toolbarBackground(Color.AppGradients.primary, for: .tabBar)
                    .toolbarBackground(Color.AppGradients.primary, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .tabBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
                AlertsView(viewModel: alertsViewModel)
                    .tabItem {
                        AlertsTabLabel(
                            isSelected: selectedTab == 1,
                            alertCount: alertsViewModel.totalAlertsCount,
                            animateTab: animateTab
                        )
                    }
                    .badge(alertsViewModel.totalAlertsCount > 0 ? alertsViewModel.totalAlertsCount : 0)
                    .tag(1)
                    .accessibilityLabel("Onglet Alertes")
                    .accessibilityValue(alertsViewModel.totalAlertsCount > 0 ? "\(alertsViewModel.totalAlertsCount) alertes" : "Aucune alerte")
                    .toolbarBackground(Color.AppGradients.primary, for: .tabBar)
                    .toolbarBackground(Color.AppGradients.primary, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .tabBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
                AddProductView(viewModel: addProductViewModel)
                    .tabItem {
                        AddProductTabLabel(isSelected: selectedTab == 2)
                    }
                    .tag(2)
                    .accessibilityLabel("Onglet Ajouter un produit")
                    .toolbarBackground(Color.AppGradients.primary, for: .tabBar)
                    .toolbarBackground(Color.AppGradients.primary, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .tabBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .onChange(of: selectedTab) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    // Animation de changement d'onglet
                }
            }
        }
        .onAppear {
            animateTab = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Application FoodStocker")
    }
}



// MARK: - Tab Label Views
struct StocksTabLabel: View {
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: isSelected ? "cube.box.fill" : "cube.box")
                .font(.system(size: 20))
                .foregroundStyle(Color.AppGradients.primary)
            Text("Stocks")
                .font(.caption.weight(.semibold))
        }
    }
}

struct AlertsTabLabel: View {
    let isSelected: Bool
    let alertCount: Int
    let animateTab: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Image(systemName: isSelected ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.AppGradients.warning)
                
                if alertCount > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 8, y: -8)
                        .scaleEffect(animateTab ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateTab)
                        .accessibilityHidden(true)
                }
            }
            Text("Alertes")
                .font(.caption.weight(.semibold))
        }
    }
}

struct AddProductTabLabel: View {
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: isSelected ? "plus.circle.fill" : "plus.circle")
                .font(.system(size: 20))
                .foregroundStyle(Color.AppGradients.success)
                .rotationEffect(.degrees(isSelected ? 180 : 0))
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isSelected)
            Text("Ajouter")
                .font(.caption.weight(.semibold))
        }
    }
}

#Preview {
    ContentView(
        productListViewModel: ProductListViewModel.mock(),
        alertsViewModel: AlertsViewModel.mock(),
        addProductViewModel: AddProductViewModel.mock()
    )
}
