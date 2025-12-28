//
//  WorkoutModes.swift
//  KurekTrack
//
//  Antrenman modları ve hedefler
//

import Foundation
import SwiftUI

// MARK: - Workout Mode
enum WorkoutMode: String, CaseIterable, Identifiable {
    case free = "free"
    case distance = "distance"
    case time = "time"
    case interval = "interval"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .free: return String(localized: "mode.free")
        case .distance: return String(localized: "mode.distance")
        case .time: return String(localized: "mode.time")
        case .interval: return String(localized: "mode.interval")
        }
    }
    
    var icon: String {
        switch self {
        case .free: return "figure.rowing"
        case .distance: return "flag.checkered"
        case .time: return "timer"
        case .interval: return "repeat"
        }
    }
    
    var color: Color {
        switch self {
        case .free: return .cyan
        case .distance: return .green
        case .time: return .orange
        case .interval: return .purple
        }
    }
}

// MARK: - Distance Goals
enum DistanceGoal: Int, CaseIterable, Identifiable {
    case m500 = 500
    case m1000 = 1000
    case m2000 = 2000
    case m5000 = 5000
    case m10000 = 10000
    
    var id: Int { rawValue }
    
    var displayName: String {
        if rawValue >= 1000 {
            return "\(rawValue / 1000) km"
        }
        return "\(rawValue) m"
    }
}

// MARK: - Time Goals
enum TimeGoal: Int, CaseIterable, Identifiable {
    case min10 = 600
    case min20 = 1200
    case min30 = 1800
    case min45 = 2700
    case min60 = 3600
    case min90 = 5400
    
    var id: Int { rawValue }
    
    var displayName: String {
        let minutes = rawValue / 60
        if minutes >= 60 {
            return "\(minutes / 60) h"
        }
        return "\(minutes) min"
    }
}

// MARK: - Interval Workout
struct IntervalWorkout: Identifiable {
    let id = UUID()
    var name: String
    var workDuration: TimeInterval  // Çalışma süresi
    var restDuration: TimeInterval  // Dinlenme süresi
    var rounds: Int                  // Tekrar sayısı
    
    var totalDuration: TimeInterval {
        Double(rounds) * (workDuration + restDuration)
    }
    
    static let presets: [IntervalWorkout] = [
        IntervalWorkout(name: "Tabata", workDuration: 20, restDuration: 10, rounds: 8),
        IntervalWorkout(name: "HIIT 30/30", workDuration: 30, restDuration: 30, rounds: 10),
        IntervalWorkout(name: "Sprint", workDuration: 60, restDuration: 120, rounds: 5),
        IntervalWorkout(name: "Pyramid", workDuration: 45, restDuration: 15, rounds: 12),
    ]
}

// MARK: - Boat Type
enum BoatType: String, CaseIterable, Identifiable {
    case single = "1x"      // Tek kişilik scull
    case double = "2x"      // Çift kişilik scull
    case pair = "2-"        // Çift kişilik sweep
    case quad = "4x"        // Dörtlü scull
    case four = "4-"        // Dörtlü sweep
    case eight = "8+"       // Sekizli
    case kayak = "K1"       // Kano/Kayak
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .single: return String(localized: "boat.single")
        case .double: return String(localized: "boat.double")
        case .pair: return String(localized: "boat.pair")
        case .quad: return String(localized: "boat.quad")
        case .four: return String(localized: "boat.four")
        case .eight: return String(localized: "boat.eight")
        case .kayak: return String(localized: "boat.kayak")
        }
    }
    
    var icon: String {
        switch self {
        case .single, .kayak: return "person.fill"
        case .double, .pair: return "person.2.fill"
        case .quad, .four: return "person.3.fill"
        case .eight: return "person.3.sequence.fill"
        }
    }
    
    var rowerCount: Int {
        switch self {
        case .single, .kayak: return 1
        case .double, .pair: return 2
        case .quad, .four: return 4
        case .eight: return 8
        }
    }
    
    // Kalori çarpanı (tekne tipine göre)
    var calorieMultiplier: Double {
        switch self {
        case .single: return 1.0
        case .double, .pair: return 0.9
        case .quad, .four: return 0.85
        case .eight: return 0.8
        case .kayak: return 1.1
        }
    }
}

// MARK: - Workout Mode Selection View
struct WorkoutModeSelectionView: View {
    @Binding var selectedMode: WorkoutMode
    @Binding var selectedBoatType: BoatType
    @Binding var distanceGoal: DistanceGoal?
    @Binding var timeGoal: TimeGoal?
    @Binding var intervalWorkout: IntervalWorkout?
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Tekne Tipi Seçimi
                        boatTypeSection
                        
                        // Antrenman Modu Seçimi
                        workoutModeSection
                        
                        // Mod'a göre ek seçenekler
                        additionalOptionsSection
                        
                        // Başlat butonu
                        startButton
                    }
                    .padding()
                }
            }
            .navigationTitle(String(localized: "mode.selectTitle"))
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
    
    // MARK: - Boat Type Section
    private var boatTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("boat.type", tableName: nil, bundle: .main, comment: "")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(BoatType.allCases) { boat in
                    BoatTypeCard(
                        boat: boat,
                        isSelected: selectedBoatType == boat
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedBoatType = boat
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Workout Mode Section
    private var workoutModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mode.workoutMode", tableName: nil, bundle: .main, comment: "")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(WorkoutMode.allCases) { mode in
                    WorkoutModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMode = mode
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Additional Options
    @ViewBuilder
    private var additionalOptionsSection: some View {
        switch selectedMode {
        case .distance:
            distanceGoalSection
        case .time:
            timeGoalSection
        case .interval:
            intervalSection
        case .free:
            EmptyView()
        }
    }
    
    private var distanceGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mode.distanceGoal", tableName: nil, bundle: .main, comment: "")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DistanceGoal.allCases) { goal in
                    GoalCard(
                        title: goal.displayName,
                        isSelected: distanceGoal == goal
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            distanceGoal = goal
                        }
                    }
                }
            }
        }
    }
    
    private var timeGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mode.timeGoal", tableName: nil, bundle: .main, comment: "")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(TimeGoal.allCases) { goal in
                    GoalCard(
                        title: goal.displayName,
                        isSelected: timeGoal == goal
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            timeGoal = goal
                        }
                    }
                }
            }
        }
    }
    
    private var intervalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mode.intervalPresets", tableName: nil, bundle: .main, comment: "")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(IntervalWorkout.presets) { interval in
                IntervalCard(
                    interval: interval,
                    isSelected: intervalWorkout?.name == interval.name
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        intervalWorkout = interval
                    }
                }
            }
        }
    }
    
    private var startButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text("mode.startWorkout", tableName: nil, bundle: .main, comment: "")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [selectedMode.color, selectedMode.color.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 8)
    }
}

// MARK: - Supporting Views
struct BoatTypeCard: View {
    let boat: BoatType
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: boat.icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .gray)
            
            Text(boat.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : .gray)
            
            Text(boat.localizedName)
                .font(.system(size: 8))
                .foregroundColor(isSelected ? .white.opacity(0.8) : .gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.cyan.opacity(0.3) : Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? .cyan : .white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
}

struct WorkoutModeCard: View {
    let mode: WorkoutMode
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: mode.icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .gray)
            
            Text(mode.localizedName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? mode.color.opacity(0.3) : Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? mode.color : .white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
}

struct GoalCard: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.3) : Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? .green : .white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
    }
}

struct IntervalCard: View {
    let interval: IntervalWorkout
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(interval.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text("\(Int(interval.workDuration))s work / \(Int(interval.restDuration))s rest × \(interval.rounds)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(formatDuration(interval.totalDuration))
                .font(.caption)
                .foregroundColor(.purple)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.purple.opacity(0.3) : Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? .purple : .white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    WorkoutModeSelectionView(
        selectedMode: .constant(.free),
        selectedBoatType: .constant(.single),
        distanceGoal: .constant(nil),
        timeGoal: .constant(nil),
        intervalWorkout: .constant(nil)
    )
}
