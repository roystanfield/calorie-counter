//
//  ContentView.swift
//  calorie_counter
//
//  Created by Roy Stanfield on 3/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var calorieManager: CalorieManager?
    @State private var selectedDayOfWeek: Int = Calendar.current.component(.weekday, from: Date())
    @State private var calorieInput: String = ""
    @State private var isRefreshingSteps = false
    @State private var showingHealthKitAlert = false
    @FocusState private var isInputFocused: Bool
    
    private let dayLabels = ["Su", "M", "T", "W", "Th", "F", "Sa"]
    private let dayNumbers = [1, 2, 3, 4, 5, 6, 7] // Sunday = 1, Monday = 2, etc.
    
    var body: some View {
        VStack(spacing: 20) {
            // Current time and timezone info
            HStack {
                VStack {
                    Text(currentTimeString)
                        .font(.headline)
                    Text(timeZoneString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh steps button
                Button(action: {
                    Task {
                        await refreshStepData()
                    }
                }) {
                    HStack {
                        if isRefreshingSteps {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Steps")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .disabled(isRefreshingSteps)
            }
            .padding(.top)
            .padding(.horizontal)
            
            // Day selector
            HStack(spacing: 0) {
                ForEach(Array(zip(dayNumbers, dayLabels)), id: \.0) { dayNumber, label in
                    Button(action: {
                        selectedDayOfWeek = dayNumber
                    }) {
                        VStack {
                            Text(label)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedDayOfWeek == dayNumber ? .white : .primary)
                            
                            if let manager = calorieManager {
                                VStack(spacing: 2) {
                                    Text("\(manager.getTotalCalories(for: dayNumber))")
                                        .font(.caption2)
                                        .foregroundColor(selectedDayOfWeek == dayNumber ? .white.opacity(0.8) : .secondary)
                                    
                                    let stepCount = manager.getStepCount(for: dayNumber)
                                    if stepCount > 0 {
                                        Text("\(formatStepCount(stepCount))")
                                            .font(.caption2)
                                            .foregroundColor(selectedDayOfWeek == dayNumber ? .white.opacity(0.6) : .secondary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedDayOfWeek == dayNumber ? Color.accentColor : Color.clear
                        )
                    }
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Calorie input
            VStack(spacing: 16) {
                Text("Add Calories")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("Enter calories", text: $calorieInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .focused($isInputFocused)
                    .onSubmit {
                        addCalories()
                    }
                    .onTapGesture {
                        isInputFocused = true
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Add") {
                                addCalories()
                            }
                            .fontWeight(.semibold)
                        }
                    }
                
                Button("Add Calories") {
                    addCalories()
                }
                .buttonStyle(.borderedProminent)
                .disabled(calorieInput.isEmpty)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Today's total with steps
            if let manager = calorieManager {
                let todayDayOfWeek = Calendar.current.component(.weekday, from: Date())
                let todayCalories = manager.getTotalCalories(for: todayDayOfWeek)
                let todaySteps = manager.getStepCount(for: todayDayOfWeek)
                
                VStack(spacing: 8) {
                    Text("Today's Total")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(todayCalories)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            Text("calories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if todaySteps > 0 {
                            VStack {
                                Text("\(formatStepCount(todaySteps))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("steps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .onAppear {
            calorieManager = CalorieManager(modelContext: modelContext)
            // Force focus immediately and with a longer delay for simulator
            isInputFocused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
        .task {
            // Additional attempt to focus when the view appears
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            isInputFocused = true
        }
        .onTapGesture {
            isInputFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Ensure keyboard shows when app becomes active
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
        .alert("Health Data Permission", isPresented: $showingHealthKitAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To display step counts, please allow access to Health data in Settings.")
        }
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private var timeZoneString: String {
        let timeZone = TimeZone.current
        return timeZone.localizedName(for: .standard, locale: Locale.current) ?? timeZone.identifier
    }
    
    private func formatStepCount(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    private func refreshStepData() async {
        guard let manager = calorieManager else { return }
        
        isRefreshingSteps = true
        
        // TODO: Implement HealthKit integration
        // For now, just simulate a brief loading state
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        await manager.refreshWeeklyStepCounts()
        isRefreshingSteps = false
    }
    
    private func addCalories() {
        guard let calories = Int(calorieInput), calories > 0 else { return }
        
        // Add calories for the selected day
        let calendar = Calendar.current
        let today = Date()
        let targetDate = getDateForSelectedDay(today)
        
        calorieManager?.addCalories(calories, for: targetDate)
        calorieInput = ""
        
        // Keep focus on the input field
        isInputFocused = true
    }
    
    private func getDateForSelectedDay(_ referenceDate: Date) -> Date {
        let calendar = Calendar.current
        let currentDayOfWeek = calendar.component(.weekday, from: referenceDate)
        
        let daysToAdd = selectedDayOfWeek - currentDayOfWeek
        
        if let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: referenceDate) {
            return targetDate
        }
        
        return referenceDate
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CalorieEntry.self, inMemory: true)
}
