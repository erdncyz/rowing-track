//
//  WorkoutHistory.swift
//  KurekTrack
//
//  Antrenman geçmişi yönetimi
//

import Foundation
import SwiftUI
import Combine

// MARK: - Workout Record
struct WorkoutRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let distance: Double // metres
    let averageSpeed: Double // km/h
    let maxSpeed: Double // km/h
    let calories: Double
    let totalStrokes: Double
    let laps: [LapRecord]
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval,
        distance: Double,
        averageSpeed: Double,
        maxSpeed: Double,
        calories: Double,
        totalStrokes: Double,
        laps: [LapRecord] = []
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.distance = distance
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.calories = calories
        self.totalStrokes = totalStrokes
        self.laps = laps
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.2f km", distance / 1000)
        }
    }
}

struct LapRecord: Identifiable, Codable {
    let id: UUID
    let number: Int
    let distance: Double
    let time: TimeInterval
    let averageSpeed: Double
    
    init(from lap: LapData) {
        self.id = lap.id
        self.number = lap.number
        self.distance = lap.distance
        self.time = lap.time
        self.averageSpeed = lap.averageSpeed
    }
    
    init(id: UUID = UUID(), number: Int, distance: Double, time: TimeInterval, averageSpeed: Double) {
        self.id = id
        self.number = number
        self.distance = distance
        self.time = time
        self.averageSpeed = averageSpeed
    }
}

// MARK: - History Manager
@MainActor
final class HistoryManager: ObservableObject {
    @Published var workouts: [WorkoutRecord] = []
    
    private let saveKey = "SavedWorkouts"
    
    init() {
        loadWorkouts()
    }
    
    func saveWorkout(_ workout: WorkoutRecord) {
        workouts.insert(workout, at: 0)
        persistWorkouts()
    }
    
    func deleteWorkout(at offsets: IndexSet) {
        workouts.remove(atOffsets: offsets)
        persistWorkouts()
    }
    
    func deleteWorkout(_ workout: WorkoutRecord) {
        workouts.removeAll { $0.id == workout.id }
        persistWorkouts()
    }
    
    private func persistWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadWorkouts() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([WorkoutRecord].self, from: data) {
            workouts = decoded
        }
    }
    
    // İstatistikler
    var totalWorkouts: Int {
        workouts.count
    }
    
    var totalDistance: Double {
        workouts.reduce(0) { $0 + $1.distance }
    }
    
    var totalDuration: TimeInterval {
        workouts.reduce(0) { $0 + $1.duration }
    }
    
    var totalCalories: Double {
        workouts.reduce(0) { $0 + $1.calories }
    }
    
    var averageSpeed: Double {
        guard !workouts.isEmpty else { return 0 }
        return workouts.reduce(0) { $0 + $1.averageSpeed } / Double(workouts.count)
    }
}

// MARK: - History View
struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color(red: 0.1, green: 0.15, blue: 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if historyManager.workouts.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Toplam istatistikler
                            summaryCard
                            
                            // Antrenman listesi
                            ForEach(historyManager.workouts) { workout in
                                WorkoutCard(workout: workout)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(String(localized: "history.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "button.close")) {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.rowing")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("history.empty", tableName: nil, bundle: .main, comment: "")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("history.startFirst", tableName: nil, bundle: .main, comment: "")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private var summaryCard: some View {
        VStack(spacing: 12) {
            Text("history.totalStats", tableName: nil, bundle: .main, comment: "")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.cyan)
            
            HStack(spacing: 20) {
                SummaryItem(
                    value: "\(historyManager.totalWorkouts)",
                    label: String(localized: "history.workouts")
                )
                
                SummaryItem(
                    value: formatDistance(historyManager.totalDistance),
                    label: String(localized: "metric.distance")
                )
                
                SummaryItem(
                    value: formatDuration(historyManager.totalDuration),
                    label: String(localized: "metric.duration")
                )
                
                SummaryItem(
                    value: String(format: "%.0f", historyManager.totalCalories),
                    label: String(localized: "metric.calories")
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

struct SummaryItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}

struct WorkoutCard: View {
    let workout: WorkoutRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tarih
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.cyan)
                Text(workout.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "figure.rowing")
                    .foregroundColor(.cyan)
            }
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Metrikler
            HStack(spacing: 16) {
                WorkoutMetric(icon: "timer", value: workout.formattedDuration, label: String(localized: "metric.duration"))
                WorkoutMetric(icon: "arrow.left.and.right", value: workout.formattedDistance, label: String(localized: "metric.distance"))
                WorkoutMetric(icon: "speedometer", value: String(format: "%.1f", workout.averageSpeed), label: String(localized: "metric.avgSpeed"))
                WorkoutMetric(icon: "flame.fill", value: String(format: "%.0f", workout.calories), label: String(localized: "metric.calories"))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct WorkoutMetric: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.cyan)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HistoryView(historyManager: HistoryManager())
}
