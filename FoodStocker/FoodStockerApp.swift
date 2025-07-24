//
//  FoodStockerApp.swift
//  FoodStocker
//
//  Created by TLiLi Hamdi on 24/07/2025.
//

import SwiftUI

@main
struct FoodStockerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
