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
    @State private var calorieInput: String = "0"
    @State private var stepCount: Int = 12134 // Mock data for now
    @State private var dailyCalorieGoal: Int = 2200
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Calorie tracking card
                        calorieTrackingCard
                        
                        // Health metrics card
                        healthMetricsCard
                        
                        Spacer(minLength: 100) // Space for keyboard
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .onAppear {
                setupInitialState()
            }
            .sheet(isPresented: .constant(isInputFocused)) {
                numericKeypadSheet
                    .presentationDetents([.height(350)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Today")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(todayDateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Calorie Tracking Card
    private var calorieTrackingCard: some View {
        VStack(spacing: 16) {
            // Calorie progress display
            calorieProgressView
            
            // Current entry row (auto-focused)
            currentEntryRow
            
            // Historical entries
            historicalEntriesView
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var calorieProgressView: some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(consumedCaloriesToday)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("/ \(dailyCalorieGoal)")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: progressBarWidth(for: geometry.size.width), height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.3), value: consumedCaloriesToday)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var currentEntryRow: some View {
        HStack {
            Text(currentTimeString)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Button(action: {
                isInputFocused = true
            }) {
                Text(calorieInput)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(calorieInput == "0" ? .blue : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(calorieInput == "0" ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(calorieInput == "0" ? Color.blue : Color.clear, lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 4)
    }
    
    private var historicalEntriesView: some View {
        VStack(spacing: 0) {
            if let manager = calorieManager {
                let entries = getTodaysEntries()
                ForEach(entries, id: \.id) { entry in
                    entryRow(for: entry)
                }
            }
        }
    }
    
    private func entryRow(for entry: CalorieEntry) -> some View {
        HStack {
            Text(formatTime(entry.date))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text("\(entry.calories)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) {
                deleteEntry(entry)
            }
            
            Button("Edit") {
                editEntry(entry)
            }
            .tint(.blue)
        }
    }
    
    // MARK: - Health Metrics Card
    private var healthMetricsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Steps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatStepCount(stepCount))
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Numeric Keypad Sheet
    private var numericKeypadSheet: some View {
        VStack(spacing: 0) {
            // Sheet header
            HStack {
                Button("Cancel") {
                    calorieInput = "0"
                    isInputFocused = false
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Button("Done") {
                    addCurrentEntry()
                }
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .disabled(calorieInput == "0" || calorieInput.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Numeric keypad
            VStack(spacing: 0) {
                ForEach(0..<4) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3) { col in
                            keypadButton(for: row, col: col)
                        }
                    }
                }
            }
            .background(Color(.systemGray6))
        }
    }
    
    private func keypadButton(for row: Int, col: Int) -> some View {
        let number = keypadNumber(for: row, col: col)
        
        return Button(action: {
            handleKeypadInput(number)
        }) {
            Group {
                if number == -1 {
                    Image(systemName: "delete.left")
                        .font(.title2)
                } else if number == -2 {
                    Text("")
                } else {
                    Text("\(number)")
                        .font(.title)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .frame(height: 60)
        .background(
            Rectangle()
                .fill(number == -2 ? Color.clear : Color(.systemBackground))
                .border(Color(.systemGray4), width: 0.5)
        )
        .disabled(number == -2)
    }
    
    // MARK: - Computed Properties
    private var consumedCaloriesToday: Int {
        guard let manager = calorieManager else { return 0 }
        return manager.getTotalCaloriesForToday()
    }
    
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
    
    // MARK: - Helper Methods
    private func setupInitialState() {
        calorieManager = CalorieManager(modelContext: modelContext)
        
        // Auto-focus the input
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isInputFocused = true
        }
    }
    
    private func getTodaysEntries() -> [CalorieEntry] {
        guard let manager = calorieManager else { return [] }
        return manager.getTodaysEntries().sorted { $0.date > $1.date }
    }
    
    private func progressBarWidth(for totalWidth: CGFloat) -> CGFloat {
        let progress = min(Double(consumedCaloriesToday) / Double(dailyCalorieGoal), 1.0)
        return totalWidth * CGFloat(progress)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatStepCount(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    private func keypadNumber(for row: Int, col: Int) -> Int {
        switch (row, col) {
        case (0, 0): return 1
        case (0, 1): return 2
        case (0, 2): return 3
        case (1, 0): return 4
        case (1, 1): return 5
        case (1, 2): return 6
        case (2, 0): return 7
        case (2, 1): return 8
        case (2, 2): return 9
        case (3, 0): return -2 // Empty space
        case (3, 1): return 0
        case (3, 2): return -1 // Delete
        default: return -2
        }
    }
    
    private func handleKeypadInput(_ number: Int) {
        if number == -1 { // Delete
            if calorieInput.count > 1 {
                calorieInput.removeLast()
            } else {
                calorieInput = "0"
            }
        } else if number >= 0 && number <= 9 {
            if calorieInput == "0" {
                calorieInput = "\(number)"
            } else {
                calorieInput += "\(number)"
            }
        }
    }
    
    private func addCurrentEntry() {
        guard let calories = Int(calorieInput), calories > 0 else {
            // Delete the row if 0 or invalid input
            calorieInput = "0"
            isInputFocused = false
            return
        }
        
        calorieManager?.addCalories(calories, for: Date())
        calorieInput = "0"
        isInputFocused = false
    }
    
    private func deleteEntry(_ entry: CalorieEntry) {
        calorieManager?.deleteEntry(entry)
    }
    
    private func editEntry(_ entry: CalorieEntry) {
        calorieInput = "\(entry.calories)"
        isInputFocused = true
        // Store the entry being edited for later update
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CalorieEntry.self, inMemory: true)
}