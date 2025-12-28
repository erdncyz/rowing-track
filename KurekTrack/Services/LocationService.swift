import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var speedKmh: Double = 0.0
    @Published var totalDistanceMeters: Double = 0.0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdating: Bool = false

    // Yalnızca GPS hızını kullanacağız
    @Published private(set) var gpsSpeedKmh: Double = 0.0

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?

    // İyileştirme parametreleri
    private let maxAllowedAccuracy: CLLocationAccuracy = 50 // m (kötü sinyali ele)
    private let minDeltaToAccumulate: CLLocationDistance = 0.5 // m (çok küçük jitter’ı yutma)

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
            isUpdating = true
            print("[LocationService] startUpdatingLocation()")
            manager.startUpdatingLocation()
        }
    }

    func stop() {
        isUpdating = false
        print("[LocationService] stopUpdatingLocation()")
        manager.stopUpdatingLocation()
    }

    func resetDistance() {
        totalDistanceMeters = 0
        lastLocation = nil
        print("[LocationService] resetDistance -> total=0, lastLocation=nil")
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

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        Task { @MainActor in
            // Teşhis log
            print(String(format: "[Location] lat=%.6f lon=%.6f acc=%.1f speed=%.2f",
                         newLocation.coordinate.latitude,
                         newLocation.coordinate.longitude,
                         newLocation.horizontalAccuracy,
                         max(newLocation.speed, 0)))

            // Accuracy filtresi
            guard newLocation.horizontalAccuracy >= 0,
                  newLocation.horizontalAccuracy <= self.maxAllowedAccuracy else {
                print("[Location] skipped due to poor accuracy:", newLocation.horizontalAccuracy)
                return
            }

            // Hız (yalnızca GPS)
            let speedMsRaw = max(newLocation.speed, 0)
            self.speedKmh = speedMsRaw * 3.6
            self.gpsSpeedKmh = self.speedKmh

            // Mesafe
            if let last = self.lastLocation {
                let delta = newLocation.distance(from: last)
                if delta >= self.minDeltaToAccumulate {
                    self.totalDistanceMeters += delta
                    print(String(format: "[Distance] +%.2f m -> total=%.2f m", delta, self.totalDistanceMeters))
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
