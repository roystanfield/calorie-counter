//
//  CalorieEntry.swift
//  calorie_counter
//
//  Created by Roy Stanfield on 3/10/26.
//

import Foundation
import SwiftData

@Model
class CalorieEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var calories: Int
    var dayOfWeek: Int // 1 = Sunday, 2 = Monday, etc.
    
    // CloudKit requires a creation timestamp for conflict resolution
    var createdAt: Date
    var modifiedAt: Date
    
    init(date: Date = Date(), calories: Int) {
        self.id = UUID()
        self.date = date
        self.calories = calories
        self.createdAt = Date()
        self.modifiedAt = Date()
        
        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: date)
    }
    
    // Update modification timestamp when data changes
    func updateModifiedDate() {
        self.modifiedAt = Date()
    }
}
