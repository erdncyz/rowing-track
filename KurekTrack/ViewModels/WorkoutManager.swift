//
//  WorkoutManager.swift
//  KurekTrack
//
//  Kürek antrenmanı yönetimi
//

import Foundation
import Combine
import CoreLocation

@MainActor
final class WorkoutManager: ObservableObject {
    // Antrenman durumu
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    
    // Zaman
    @Published var elapsedTime: TimeInterval = 0
    private var startDate: Date?
    private var pausedTime: TimeInterval = 0
    private var timer: Timer?
    
    // Hız istatistikleri
    @Published var averageSpeed: Double = 0
    @Published var maxSpeed: Double = 0
    private var speedReadings: [Double] = []
    
    // Kürek istatistikleri (simülasyon - gerçek uygulamada sensör gerekir)
    @Published var strokeRate: Double = 0  // Kürek/dakika (SPM)
    @Published var totalStrokes: Double = 0
    
    // Kalori
    @Published var calories: Double = 0
    private let caloriesPerKm: Double = 50 // Ortalama kalori/km
    
    // Tur bilgileri
    @Published var laps: [LapData] = []
    private var lapStartDistance: Double = 0
    private var lapStartTime: TimeInterval = 0
    
    // Location service referansı
    weak var locationService: LocationService? {
        didSet {
            setupLocationObserver()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var lastDistance: Double = 0
    
    init() {}
    
    // MARK: - Kontrol Fonksiyonları
    
    func start() {
        if isPaused {
            // Devam et
            startDate = Date().addingTimeInterval(-pausedTime)
            isPaused = false
        } else {
            // Yeni başlat
            startDate = Date()
            pausedTime = 0
        }
        
        isActive = true
        startTimer()
        
        print("[WorkoutManager] Started")
    }
    
    func pause() {
        isActive = false
        isPaused = true
        pausedTime = elapsedTime
        stopTimer()
        
        print("[WorkoutManager] Paused at \(formattedTime)")
    }
    
    func reset() {
        isActive = false
        isPaused = false
        stopTimer()
        
        elapsedTime = 0
        startDate = nil
        pausedTime = 0
        
        averageSpeed = 0
        maxSpeed = 0
        speedReadings.removeAll()
        
        strokeRate = 0
        totalStrokes = 0
        
        calories = 0
        
        laps.removeAll()
        lapStartDistance = 0
        lapStartTime = 0
        lastDistance = 0
        
        print("[WorkoutManager] Reset")
    }
    
    func addLap() {
        guard let locationService = locationService else { return }
        
        let currentDistance = locationService.totalDistanceMeters
        let lapDistance = currentDistance - lapStartDistance
        let lapTime = elapsedTime - lapStartTime
        
        let lap = LapData(
            number: laps.count + 1,
            distance: lapDistance,
            time: lapTime,
            averageSpeed: lapTime > 0 ? (lapDistance / 1000) / (lapTime / 3600) : 0
        )
        
        laps.append(lap)
        lapStartDistance = currentDistance
        lapStartTime = elapsedTime
        
        print("[WorkoutManager] Lap \(lap.number) added: \(lap.formattedDistance) in \(lap.formattedTime)")
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTime()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTime() {
        guard let start = startDate, isActive else { return }
        elapsedTime = Date().timeIntervalSince(start)
    }
    
    // MARK: - Location Observer
    
    private func setupLocationObserver() {
        cancellables.removeAll()
        
        guard let locationService = locationService else { return }
        
        // Hız değişimlerini takip et
        locationService.$gpsSpeedKmh
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speed in
                self?.updateSpeedStats(speed)
            }
            .store(in: &cancellables)
        
        // Mesafe değişimlerini takip et
        locationService.$totalDistanceMeters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] distance in
                self?.updateDistanceBasedStats(distance)
            }
            .store(in: &cancellables)
    }
    
    private func updateSpeedStats(_ currentSpeed: Double) {
        guard isActive else { return }
        
        // Hız okumalarını kaydet
        if currentSpeed > 0 {
            speedReadings.append(currentSpeed)
            
            // Ortalama hız
            averageSpeed = speedReadings.reduce(0, +) / Double(speedReadings.count)
            
            // Maksimum hız
            if currentSpeed > maxSpeed {
                maxSpeed = currentSpeed
            }
        }
        
        // Kürek hızını tahmin et (hıza göre simülasyon)
        // Gerçek uygulamada akselerometre veya harici sensör kullanılır
        if currentSpeed > 0 {
            strokeRate = estimateStrokeRate(speed: currentSpeed)
        } else {
            strokeRate = 0
        }
    }
    
    private func updateDistanceBasedStats(_ currentDistance: Double) {
        guard isActive else { return }
        
        let deltaDistance = currentDistance - lastDistance
        
        if deltaDistance > 0 {
            // Kalori hesapla
            let deltaKm = deltaDistance / 1000
            calories += deltaKm * caloriesPerKm
            
            // Toplam kürek sayısını tahmin et
            // Ortalama olarak her kürek yaklaşık 8-10 metre mesafe kat eder
            let strokesForDelta = deltaDistance / 9.0
            totalStrokes += strokesForDelta
        }
        
        lastDistance = currentDistance
    }
    
    // Hıza göre kürek hızı tahmini (SPM - Strokes Per Minute)
    private func estimateStrokeRate(speed: Double) -> Double {
        // Tipik kürek çekme hızları:
        // Yavaş: 18-22 SPM, Orta: 24-28 SPM, Hızlı: 30-36 SPM
        // Hız arttıkça SPM de artar
        
        let baseSPM: Double = 18
        let speedFactor: Double = speed / 5.0 // 5 km/h referans
        let estimatedSPM = baseSPM + (speedFactor * 8)
        
        return min(max(estimatedSPM, 16), 40) // 16-40 SPM arasında sınırla
    }
    
    // MARK: - Formatters
    
    var formattedTime: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var formattedPace: String {
        // 500m için pace hesapla
        guard averageSpeed > 0 else { return "--:--" }
        
        // Dakika/500m = (500 / 1000) / (hız km/h / 60)
        let paceMinutes = (0.5 / averageSpeed) * 60
        let totalSeconds = Int(paceMinutes * 60)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Lap Data
struct LapData: Identifiable {
    let id = UUID()
    let number: Int
    let distance: Double // metres
    let time: TimeInterval
    let averageSpeed: Double // km/h
    
    var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.2f km", distance / 1000)
        }
    }
    
    var formattedTime: String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
