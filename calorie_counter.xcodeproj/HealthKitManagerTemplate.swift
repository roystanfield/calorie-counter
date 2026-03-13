//
//  HealthKitManager.swift
//  calorie_counter
//
//  Created by Roy Stanfield on 3/10/26.
//

import Foundation
import HealthKit

@Observable
class HealthKitManager {
    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false
    private(set) var authorizationError: Error?
    
    init() {
        checkAuthorizationStatus()
    }
    
    /// Check if HealthKit is available and request permissions
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let typesToRead: Set<HKObjectType> = [stepCountType]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await MainActor.run {
                self.isAuthorized = true
                self.authorizationError = nil
            }
            print("HealthKit authorization granted")
        } catch {
            await MainActor.run {
                self.isAuthorized = false
                self.authorizationError = error
            }
            print("HealthKit authorization failed: \(error)")
        }
    }
    
    /// Fetch step count for a specific date
    func getStepCount(for date: Date) async -> Int {
        guard isAuthorized else {
            print("HealthKit not authorized")
            return 0
        }
        
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("Error fetching step count: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch step counts for multiple dates (useful for the week view)
    func getStepCounts(for dates: [Date]) async -> [Date: Int] {
        var stepCounts: [Date: Int] = [:]
        
        for date in dates {
            let steps = await getStepCount(for: date)
            stepCounts[date] = steps
        }
        
        return stepCounts
    }
    
    /// Get step counts for the current week (Sunday to Saturday)
    func getWeeklyStepCounts() async -> [Int: Int] {
        let calendar = Calendar.current
        let today = Date()
        var weeklySteps: [Int: Int] = [:]
        
        // Get dates for each day of the week (1=Sunday, 2=Monday, etc.)
        for dayOfWeek in 1...7 {
            let daysToAdd = dayOfWeek - calendar.component(.weekday, from: today)
            if let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) {
                let steps = await getStepCount(for: targetDate)
                weeklySteps[dayOfWeek] = steps
            }
        }
        
        return weeklySteps
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepCountType)
        
        self.isAuthorized = status == .sharingAuthorized
    }
}