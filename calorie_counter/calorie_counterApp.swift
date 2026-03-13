//
//  calorie_counterApp.swift
//  calorie_counter
//
//  Created by Roy Stanfield on 3/10/26.
//

import SwiftUI
import SwiftData

@main
struct calorie_counterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(createModelContainer())
    }
    
    private func createModelContainer() -> ModelContainer {
        do {
            // Create a configuration for CloudKit
            let configuration = ModelConfiguration(
                "CalorieData",
                schema: Schema([CalorieEntry.self]),
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            let container = try ModelContainer(for: CalorieEntry.self, configurations: configuration)
            print("CloudKit-enabled container created successfully")
            return container
        } catch {
            print("Failed to create CloudKit container: \(error)")
            
            // Fallback to local storage only
            do {
                let fallbackContainer = try ModelContainer(for: CalorieEntry.self)
                print("Using local-only container")
                return fallbackContainer
            } catch {
                fatalError("Could not create any container: \(error)")
            }
        }
    }
}
