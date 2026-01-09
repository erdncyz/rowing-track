import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var speedKmh: Double = 0.0
    @Published var totalDistanceMeters: Double = 0.0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdating: Bool = false

    // Yalnızca GPS hızını kullanacağız
    @Published private(set) var gpsSpeedKmh: Double = 0.0

    /// Veri kaydı yapılıyor mu? (WorkoutManager tarafından kontrol edilir)
    @Published var isRecording: Bool = false

    // MARK: - Dahili Değişkenler
    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var speedReadings: [Double] = []  // Hız ortalaması için buffer

    // İyileştirme parametreleri
    private let maxAllowedAccuracy: CLLocationAccuracy = 50  // m (kötü sinyali ele)
    private let minDeltaToAccumulate: CLLocationDistance = 0.5  // m (çok küçük jitter’ı yutma)
    private let minSpeedThreshold: Double = 0.5  // m/s (Hız yumuşatma ve mesafe filtresi için)

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false

        print("[LocationService] init, current auth:", manager.authorizationStatus.rawValue)
    }

    func requestAuthorization() {
        print("[LocationService] requestWhenInUseAuthorization()")
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        Task { @MainActor in
            let enabled = await Task.detached {
                CLLocationManager.locationServicesEnabled()
            }.value

            guard enabled else {
                print("[LocationService] location services disabled")
                return
            }

            // Başlarken bufferları temizle
            speedReadings.removeAll()
            lastLocation = nil

            isUpdating = true
            print("[LocationService] startUpdatingLocation()")
            manager.startUpdatingLocation()
        }
    }

    func stop() {
        isUpdating = false
        isRecording = false
        print("[LocationService] stopUpdatingLocation()")
        manager.stopUpdatingLocation()
    }

    func resetDistance() {
        totalDistanceMeters = 0
        lastLocation = nil
        speedReadings.removeAll()
        speedKmh = 0
        gpsSpeedKmh = 0
        print("[LocationService] resetDistance -> total=0")
    }

    // Hız yumuşatma için yardımcı fonksiyon
    private func updateSmoothedSpeed(_ instantSpeedMs: Double) {
        let bufferSize = 5  // Son 5 okumanın ortalamasını al
        speedReadings.append(instantSpeedMs)
        if speedReadings.count > bufferSize {
            speedReadings.removeFirst()
        }

        let smoothedSpeedMs = speedReadings.reduce(0, +) / Double(speedReadings.count)
        self.speedKmh = smoothedSpeedMs * 3.6
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            self.authorizationStatus = status
            print("[LocationService] didChangeAuthorization:", status.rawValue)

            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                self.start()
            case .denied, .restricted, .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        guard let newLocation = locations.last else { return }

        // Veri 5 saniyeden eskiyse kullanma
        guard abs(newLocation.timestamp.timeIntervalSinceNow) < 5.0 else { return }

        Task { @MainActor in
            // Teşhis log
            print(
                String(
                    format: "[Location] lat=%.6f lon=%.6f acc=%.1f speed=%.2f",
                    newLocation.coordinate.latitude,
                    newLocation.coordinate.longitude,
                    newLocation.horizontalAccuracy,
                    max(newLocation.speed, 0)))

            // 1. Hassasiyet Filtresi
            guard newLocation.horizontalAccuracy >= 0,
                newLocation.horizontalAccuracy <= self.maxAllowedAccuracy
            else {
                print("[Location] skipped due to poor accuracy:", newLocation.horizontalAccuracy)
                return
            }

            // Eğer kayıt modunda değilsek:
            // Sadece konum referansını (lastLocation) güncelle ki "Start" dendiğinde zıplama olmasın.
            // Hız ve mesafeyi 0'da tut.
            guard isRecording else {
                self.speedKmh = 0
                self.gpsSpeedKmh = 0
                self.lastLocation = newLocation
                return
            }

            // 2. Anlık Ham Hız
            let instantSpeedMs = max(newLocation.speed, 0)
            self.gpsSpeedKmh = instantSpeedMs * 3.6

            // 3. Hız Yumuşatma (Smoothing)
            self.updateSmoothedSpeed(instantSpeedMs)

            // 4. Mesafe Hesaplama
            if let last = self.lastLocation {
                let delta = newLocation.distance(from: last)

                // Drift Filtresi
                let isMovingFastEnough = instantSpeedMs > self.minSpeedThreshold

                if isMovingFastEnough || delta > 2.0 {
                    self.totalDistanceMeters += delta
                    print(
                        String(
                            format: "[Distance] +%.2f m -> total=%.2f m", delta,
                            self.totalDistanceMeters))
                } else {
                    // Çok küçük jitter’ı yut
                }
            } else {
                print("[Distance] first fix set.")
            }

            self.lastLocation = newLocation
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationService] didFailWithError:", error.localizedDescription)
    }
}
