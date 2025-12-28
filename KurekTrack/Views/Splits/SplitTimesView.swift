//
//  SplitTimesView.swift
//  KurekTrack
//
//  Split zamanları ve performans analizi
//

import Foundation
import SwiftUI
import Combine

// MARK: - Split Data
struct SplitData: Identifiable {
    let id = UUID()
    let distance: Int           // metre (500, 1000, etc.)
    let time: TimeInterval      // saniye
    let speed: Double           // km/h
    let strokeRate: Double      // SPM
    
    var pace500m: TimeInterval {
        // 500m için pace hesapla
        return (time / Double(distance)) * 500
    }
    
    var formattedPace: String {
        let minutes = Int(pace500m) / 60
        let seconds = Int(pace500m) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedTime: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Performance Rating
enum PerformanceRating: String {
    case elite = "elite"
    case excellent = "excellent"
    case good = "good"
    case average = "average"
    case beginner = "beginner"
    
    var localizedName: String {
        switch self {
        case .elite: return String(localized: "performance.elite")
        case .excellent: return String(localized: "performance.excellent")
        case .good: return String(localized: "performance.good")
        case .average: return String(localized: "performance.average")
        case .beginner: return String(localized: "performance.beginner")
        }
    }
    
    var color: Color {
        switch self {
        case .elite: return .purple
        case .excellent: return .green
        case .good: return .cyan
        case .average: return .yellow
        case .beginner: return .orange
        }
    }
    
    // 500m pace'e göre rating (saniye cinsinden)
    static func fromPace(_ paceSeconds: TimeInterval, boatType: BoatType = .single) -> PerformanceRating {
        // Tekne tipine göre ayarlama
        let adjustedPace = paceSeconds * boatType.calorieMultiplier
        
        switch adjustedPace {
        case 0..<90: return .elite        // < 1:30
        case 90..<105: return .excellent  // 1:30 - 1:45
        case 105..<120: return .good      // 1:45 - 2:00
        case 120..<150: return .average   // 2:00 - 2:30
        default: return .beginner         // > 2:30
        }
    }
}

// MARK: - Split Times Manager
@MainActor
final class SplitTimesManager: ObservableObject {
    @Published var splits: [SplitData] = []
    @Published var currentSplitDistance: Int = 0
    @Published var splitInterval: Int = 500  // Her kaç metrede split alınacak
    
    private var lastSplitDistance: Int = 0
    private var lastSplitTime: TimeInterval = 0
    
    func checkForNewSplit(distance: Double, time: TimeInterval, speed: Double, strokeRate: Double) {
        let currentMeter = Int(distance)
        let nextSplitMark = lastSplitDistance + splitInterval
        
        if currentMeter >= nextSplitMark && currentMeter > 0 {
            let splitTime = time - lastSplitTime
            
            let split = SplitData(
                distance: splitInterval,
                time: splitTime,
                speed: speed,
                strokeRate: strokeRate
            )
            
            splits.append(split)
            lastSplitDistance = nextSplitMark
            lastSplitTime = time
            
            print("[Split] New split at \(nextSplitMark)m: \(split.formattedPace)/500m")
        }
        
        currentSplitDistance = currentMeter - lastSplitDistance
    }
    
    func reset() {
        splits.removeAll()
        currentSplitDistance = 0
        lastSplitDistance = 0
        lastSplitTime = 0
    }
    
    var averagePace: TimeInterval {
        guard !splits.isEmpty else { return 0 }
        let totalPace = splits.reduce(0) { $0 + $1.pace500m }
        return totalPace / Double(splits.count)
    }
    
    var bestPace: TimeInterval {
        splits.map { $0.pace500m }.min() ?? 0
    }
    
    var worstPace: TimeInterval {
        splits.map { $0.pace500m }.max() ?? 0
    }
}

// MARK: - Split Times View
struct SplitTimesView: View {
    @ObservedObject var splitManager: SplitTimesManager
    let boatType: BoatType
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
                
                if splitManager.splits.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Özet kartı
                            summaryCard
                            
                            // Split listesi
                            splitsListView
                            
                            // Performans grafiği
                            performanceChartView
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(String(localized: "splits.title"))
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
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("splits.noData", tableName: nil, bundle: .main, comment: "")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("splits.keepRowing", tableName: nil, bundle: .main, comment: "")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private var summaryCard: some View {
        VStack(spacing: 12) {
            // Performans rating
            let rating = PerformanceRating.fromPace(splitManager.averagePace, boatType: boatType)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("splits.performance", tableName: nil, bundle: .main, comment: "")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(rating.localizedName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(rating.color)
                }
                
                Spacer()
                
                // Ortalama pace
                VStack(alignment: .trailing) {
                    Text("splits.avgPace", tableName: nil, bundle: .main, comment: "")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formatPace(splitManager.averagePace))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("/500m")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Best/Worst pace
            HStack(spacing: 24) {
                VStack {
                    Text("splits.best", tableName: nil, bundle: .main, comment: "")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(formatPace(splitManager.bestPace))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack {
                    Text("splits.worst", tableName: nil, bundle: .main, comment: "")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(formatPace(splitManager.worstPace))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack {
                    Text("splits.total", tableName: nil, bundle: .main, comment: "")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Text("\(splitManager.splits.count)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var splitsListView: some View {
        VStack(spacing: 8) {
            // Başlık
            HStack {
                Text("#")
                    .frame(width: 30)
                Text("splits.pace", tableName: nil, bundle: .main, comment: "")
                    .frame(maxWidth: .infinity)
                Text("splits.speed", tableName: nil, bundle: .main, comment: "")
                    .frame(width: 60)
                Text("SPM")
                    .frame(width: 50)
            }
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.horizontal)
            
            ForEach(Array(splitManager.splits.enumerated()), id: \.element.id) { index, split in
                SplitRowView(
                    index: index + 1,
                    split: split,
                    bestPace: splitManager.bestPace
                )
            }
        }
    }
    
    private var performanceChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("splits.chart", tableName: nil, bundle: .main, comment: "")
                .font(.headline)
                .foregroundColor(.white)
            
            // Basit bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(splitManager.splits.enumerated()), id: \.element.id) { index, split in
                    let maxPace = splitManager.worstPace
                    let minPace = splitManager.bestPace
                    let range = max(maxPace - minPace, 1)
                    let normalizedHeight = 1 - ((split.pace500m - minPace) / range)
                    let height = max(normalizedHeight * 100, 20)
                    
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(for: split.pace500m))
                            .frame(height: height)
                        
                        Text("\(index + 1)")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(height: 120)
            .padding(.horizontal)
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
    
    private func formatPace(_ pace: TimeInterval) -> String {
        guard pace > 0 else { return "--:--" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func barColor(for pace: TimeInterval) -> Color {
        let rating = PerformanceRating.fromPace(pace, boatType: boatType)
        return rating.color
    }
}

struct SplitRowView: View {
    let index: Int
    let split: SplitData
    let bestPace: TimeInterval
    
    var body: some View {
        HStack {
            // Index
            Text("\(index)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.cyan)
                .frame(width: 30)
            
            // Pace with indicator
            HStack(spacing: 4) {
                Text(split.formattedPace)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if split.pace500m == bestPace {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Speed
            Text(String(format: "%.1f", split.speed))
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 60)
            
            // Stroke rate
            Text(String(format: "%.0f", split.strokeRate))
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 50)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(index % 2 == 0 ? Color.gray.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Live Split Indicator
struct LiveSplitIndicator: View {
    let currentDistance: Int
    let splitInterval: Int
    let currentPace: TimeInterval
    
    var progress: Double {
        Double(currentDistance) / Double(splitInterval)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(currentDistance)m")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(splitInterval)m")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    SplitTimesView(
        splitManager: SplitTimesManager(),
        boatType: .single
    )
}
