//
//  NavigationTestView.swift
//  FoodStocker
//
//  Test pour vérifier la navigation
//

import SwiftUI

struct NavigationTestView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Arrière-plan de test - Color1 et Color2 DOMINANTES
                LinearGradient(
                    colors: [
                        Color.appColor1.opacity(0.75),
                        Color.appColor2.opacity(0.65),
                        Color.appColor1.opacity(0.5),
                        Color.appColor2.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
            VStack(spacing: 20) {
                Text("Test de Navigation")
                    .font(.title.weight(.bold))
                
                NavigationLink("Vers ProductListView", destination: ProductListView(viewModel: ProductListViewModel.mock()))
                NavigationLink("Vers AlertsView", destination: AlertsView(viewModel: AlertsViewModel.mock()))
                NavigationLink("Vers AddProductView", destination: AddProductView(viewModel: AddProductViewModel.mock()))
            }
            .padding()
            }
        }
    }
}

#Preview {
    NavigationTestView()
}