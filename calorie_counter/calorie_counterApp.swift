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
        .modelContainer(for: CalorieEntry.self)
    }
}
