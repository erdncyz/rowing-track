//
//  WeatherService.swift
//  KurekTrack
//
//  Hava ve su durumu servisi
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Weather Data
struct WeatherData: Codable {
    var temperature: Double         // Celsius
    var feelsLike: Double           // Hissedilen sıcaklık
    var humidity: Int               // Nem %
    var windSpeed: Double           // km/h
    var windDirection: Double       // Derece (0-360)
    var weatherCondition: String    // Hava durumu
    var uvIndex: Int                // UV indeksi
    var visibility: Double          // Görüş mesafesi km
    var locationName: String?       // Konum adı (şehir, bölge)
    var updatedAt: Date
    
    var windDirectionText: String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((windDirection + 22.5) / 45.0) % 8
        return directions[index]
    }
    
    var windDirectionLocalizedText: String {
        switch windDirectionText {
        case "N": return String(localized: "wind.north")
        case "NE": return String(localized: "wind.northeast")
        case "E": return String(localized: "wind.east")
        case "SE": return String(localized: "wind.southeast")
        case "S": return String(localized: "wind.south")
        case "SW": return String(localized: "wind.southwest")
        case "W": return String(localized: "wind.west")
        case "NW": return String(localized: "wind.northwest")
        default: return windDirectionText
        }
    }
    
    var weatherIcon: String {
        switch weatherCondition.lowercased() {
        case "clear", "sunny": return "sun.max.fill"
        case "cloudy", "overcast": return "cloud.fill"
        case "partly cloudy": return "cloud.sun.fill"
        case "rain", "rainy": return "cloud.rain.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "snow": return "cloud.snow.fill"
        case "fog", "mist": return "cloud.fog.fill"
        case "windy": return "wind"
        default: return "cloud.sun.fill"
        }
    }
    
    var rowingCondition: RowingCondition {
        // Kürek çekme için uygunluk değerlendirmesi
        if windSpeed > 30 || weatherCondition.lowercased().contains("thunder") {
            return .dangerous
        } else if windSpeed > 20 || weatherCondition.lowercased().contains("rain") {
            return .poor
        } else if windSpeed > 12 {
            return .fair
        } else if temperature >= 10 && temperature <= 28 && windSpeed < 8 {
            return .excellent
        } else {
            return .good
        }
    }
    
    static let placeholder = WeatherData(
        temperature: 20,
        feelsLike: 19,
        humidity: 65,
        windSpeed: 8,
        windDirection: 180,
        weatherCondition: "Partly Cloudy",
        uvIndex: 4,
        visibility: 10,
        locationName: "İstanbul, Türkiye",
        updatedAt: Date()
    )
}

// MARK: - Rowing Condition
enum RowingCondition: String {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case dangerous = "dangerous"
    
    var localizedName: String {
        switch self {
        case .excellent: return String(localized: "condition.excellent")
        case .good: return String(localized: "condition.good")
        case .fair: return String(localized: "condition.fair")
        case .poor: return String(localized: "condition.poor")
        case .dangerous: return String(localized: "condition.dangerous")
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .cyan
        case .fair: return .yellow
        case .poor: return .orange
        case .dangerous: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "hand.thumbsup.fill"
        case .fair: return "exclamationmark.triangle.fill"
        case .poor: return "xmark.circle.fill"
        case .dangerous: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Water Conditions
struct WaterConditions {
    var waveHeight: Double      // metre
    var waterTemperature: Double // Celsius
    var currentSpeed: Double    // km/h
    var currentDirection: Double // Derece
    
    var waveDescription: String {
        switch waveHeight {
        case 0..<0.1: return String(localized: "wave.calm")
        case 0.1..<0.3: return String(localized: "wave.smooth")
        case 0.3..<0.5: return String(localized: "wave.slight")
        case 0.5..<1.0: return String(localized: "wave.moderate")
        case 1.0..<2.0: return String(localized: "wave.rough")
        default: return String(localized: "wave.veryRough")
        }
    }
    
    static let placeholder = WaterConditions(
        waveHeight: 0.2,
        waterTemperature: 18,
        currentSpeed: 2,
        currentDirection: 90
    )
}

// MARK: - Weather View
struct WeatherView: View {
    let weather: WeatherData
    let waterConditions: WaterConditions
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
                    VStack(spacing: 20) {
                        // Konum ve güncelleme zamanı
                        locationHeader
                        
                        // Kürek durumu kartı
                        rowingConditionCard
                        
                        // Hava durumu kartı
                        weatherCard
                        
                        // Rüzgar kartı
                        windCard
                        
                        // Su durumu kartı
                        waterCard
                    }
                    .padding()
                }
            }
            .navigationTitle(String(localized: "weather.title"))
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
    
    // MARK: - Location Header
    private var locationHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.cyan)
                
                Text(weather.locationName ?? String(localized: "weather.location.unknown"))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text(weather.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(String(localized: "weather.updated"))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.3))
        )
    }
    
    // MARK: - Rowing Condition Card
    private var rowingConditionCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: weather.rowingCondition.icon)
                    .font(.title)
                    .foregroundColor(weather.rowingCondition.color)
                
                VStack(alignment: .leading) {
                    Text("weather.rowingConditions", tableName: nil, bundle: .main, comment: "")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(weather.rowingCondition.localizedName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(weather.rowingCondition.color)
                }
                
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(weather.rowingCondition.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(weather.rowingCondition.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Weather Card
    private var weatherCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("weather.current", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: weather.weatherIcon)
                    .font(.title)
                    .foregroundColor(.yellow)
            }
            
            HStack(spacing: 24) {
                WeatherItem(
                    icon: "thermometer.medium",
                    value: String(format: "%.0f°", weather.temperature),
                    label: String(localized: "weather.temp")
                )
                
                WeatherItem(
                    icon: "thermometer.variable.and.figure",
                    value: String(format: "%.0f°", weather.feelsLike),
                    label: String(localized: "weather.feelsLike")
                )
                
                WeatherItem(
                    icon: "humidity.fill",
                    value: "\(weather.humidity)%",
                    label: String(localized: "weather.humidity")
                )
                
                WeatherItem(
                    icon: "sun.max.fill",
                    value: "\(weather.uvIndex)",
                    label: "UV"
                )
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
    
    // MARK: - Wind Card
    private var windCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("weather.wind", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 24) {
                // Rüzgar hızı
                VStack(spacing: 4) {
                    Image(systemName: "wind")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    
                    Text(String(format: "%.1f", weather.windSpeed))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("km/h")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                
                // Rüzgar yönü göstergesi
                ZStack {
                    Circle()
                        .stroke(.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                    
                    // Yön oku
                    Image(systemName: "arrow.up")
                        .font(.title)
                        .foregroundColor(.cyan)
                        .rotationEffect(.degrees(weather.windDirection))
                    
                    // Yön harfleri
                    ForEach(["N", "E", "S", "W"], id: \.self) { direction in
                        Text(direction)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .offset(directionOffset(for: direction))
                    }
                }
                
                // Rüzgar yönü
                VStack(spacing: 4) {
                    Image(systemName: "location.north.fill")
                        .font(.title2)
                        .foregroundColor(.cyan)
                        .rotationEffect(.degrees(weather.windDirection))
                    
                    Text(weather.windDirectionLocalizedText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(String(format: "%.0f°", weather.windDirection))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.cyan.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Water Card
    private var waterCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("weather.water", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 24) {
                WeatherItem(
                    icon: "water.waves",
                    value: waterConditions.waveDescription,
                    label: String(localized: "weather.waves")
                )
                
                WeatherItem(
                    icon: "thermometer.snowflake",
                    value: String(format: "%.0f°", waterConditions.waterTemperature),
                    label: String(localized: "weather.waterTemp")
                )
                
                WeatherItem(
                    icon: "arrow.triangle.swap",
                    value: String(format: "%.1f", waterConditions.currentSpeed),
                    label: String(localized: "weather.current")
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func directionOffset(for direction: String) -> CGSize {
        switch direction {
        case "N": return CGSize(width: 0, height: -50)
        case "E": return CGSize(width: 50, height: 0)
        case "S": return CGSize(width: 0, height: 50)
        case "W": return CGSize(width: -50, height: 0)
        default: return .zero
        }
    }
}

struct WeatherItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cyan)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    WeatherView(
        weather: WeatherData(
            temperature: 22,
            feelsLike: 20,
            humidity: 65,
            windSpeed: 12,
            windDirection: 180,
            weatherCondition: "Clear",
            uvIndex: 5,
            visibility: 10,
            locationName: "İstanbul, Beşiktaş",
            updatedAt: Date()
        ),
        waterConditions: WaterConditions.placeholder
    )
}
