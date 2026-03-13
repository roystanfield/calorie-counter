//
//  CalorieManager.swift
//  calorie_counter
//
//  Created by Roy Stanfield on 3/10/26.
//

import Foundation
import SwiftData

@Observable
class CalorieManager {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addCalories(_ calories: Int, for date: Date = Date()) {
        let entry = CalorieEntry(calories: calories, date: date)
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            print("Calories saved successfully and will sync to CloudKit")
        } catch {
            print("Failed to save calories: \(error)")
        }
    }
    
    func getTotalCalories(for dayOfWeek: Int, in timeZone: TimeZone = TimeZone.current) -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        // Find the most recent occurrence of this day of week
        let targetDate = getDateForDayOfWeek(dayOfWeek, relativeTo: today, in: timeZone)
        
        // Get start and end of that day in the user's timezone
        let startOfDay = calendar.startOfDay(for: targetDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<CalorieEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<CalorieEntry>(predicate: predicate)
        
        do {
            let entries = try modelContext.fetch(descriptor)
            return entries.reduce(0) { $0 + $1.calories }
        } catch {
            print("Failed to fetch calories: \(error)")
            return 0
        }
    }
    
    func getTotalCaloriesForToday() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<CalorieEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<CalorieEntry>(predicate: predicate)
        
        do {
            let entries = try modelContext.fetch(descriptor)
            return entries.reduce(0) { $0 + $1.calories }
        } catch {
            print("Failed to fetch calories: \(error)")
            return 0
        }
    }
    
    func getTodaysEntries() -> [CalorieEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<CalorieEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<CalorieEntry>(predicate: predicate)
        
        do {
            let entries = try modelContext.fetch(descriptor)
            return entries
        } catch {
            print("Failed to fetch today's entries: \(error)")
            return []
        }
    }
    
    func deleteEntry(_ entry: CalorieEntry) {
        modelContext.delete(entry)
        
        do {
            try modelContext.save()
            print("Entry deleted successfully")
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }
    
    /// Get step count for a specific day of the week (placeholder - returns 0)
    func getStepCount(for dayOfWeek: Int, in timeZone: TimeZone = TimeZone.current) -> Int {
        // TODO: Implement HealthKit integration
        // For now, return 0 until HealthKit is properly set up
        return 0
    }
    
    /// Update step count data for a specific date (placeholder)
    func updateStepCount(_ steps: Int, for date: Date) async {
        // TODO: Implement HealthKit integration
        print("Step count update requested: \(steps) steps for \(date)")
    }
    
    /// Refresh step count data from HealthKit for all days of the week (placeholder)
    func refreshWeeklyStepCounts() async {
        // TODO: Implement HealthKit integration
        print("Weekly step count refresh requested")
    }
    
    private func getDateForDayOfWeek(_ dayOfWeek: Int, relativeTo date: Date, in timeZone: TimeZone) -> Date {
        let calendar = Calendar.current
        let currentDayOfWeek = calendar.component(.weekday, from: date)
        
        let daysToAdd = dayOfWeek - currentDayOfWeek
        
        if let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: date) {
            return targetDate
        }
        
        return date
    }
}
