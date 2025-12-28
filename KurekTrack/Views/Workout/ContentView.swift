//
//  ContentView.swift
//  KurekTrack
//
//  Created by Ahmet Sirma on 12.11.2025.
//

import SwiftUI
import MapKit
import Combine

struct ContentView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var splitTimesManager = SplitTimesManager()
    @StateObject private var audioCoachManager = AudioCoachManager()
    @StateObject private var settingsManager = SettingsManager()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showingMap = false
    @State private var showingSaveAlert = false
    @State private var showingWorkoutModes = false
    @State private var selectedTab = 0
    
    // Workout mode states
    @State private var selectedWorkoutMode: WorkoutMode = .free
    @State private var selectedBoatType: BoatType = .single
    @State private var distanceGoal: DistanceGoal? = nil
    @State private var timeGoal: TimeGoal? = nil
    @State private var intervalWorkout: IntervalWorkout? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Ana Antrenman Ekranı
            workoutTab
                .tabItem {
                    Label(String(localized: "tab.workout"), systemImage: "figure.outdoor.rowing")
                }
                .tag(0)
            
            // Tab 2: Geçmiş
            HistoryView(historyManager: historyManager)
                .tabItem {
                    Label(String(localized: "tab.history"), systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
            
            // Tab 3: Split Zamanları
            SplitTimesView(splitManager: splitTimesManager, boatType: selectedBoatType)
                .tabItem {
                    Label(String(localized: "tab.splits"), systemImage: "timer")
                }
                .tag(2)
            
            // Tab 4: Hava Durumu
            WeatherView(weather: .placeholder, waterConditions: .placeholder)
                .tabItem {
                    Label(String(localized: "tab.weather"), systemImage: "cloud.sun.fill")
                }
                .tag(3)
            
            // Tab 5: Ayarlar
            SettingsView(settingsManager: settingsManager)
                .tabItem {
                    Label(String(localized: "tab.settings"), systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.cyan)
        .onAppear {
            // TabBar görünümünü özelleştir
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(red: 0.05, green: 0.1, blue: 0.2))
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            workoutManager.locationService = locationService
        }
        .onChange(of: workoutManager.isActive) { _, isActive in
            if isActive {
                audioCoachManager.announceWorkoutStart()
                audioCoachManager.startTempoBeep()
            } else {
                audioCoachManager.announceWorkoutPause()
                audioCoachManager.stopTempoBeep()
            }
        }
        .onChange(of: locationService.totalDistanceMeters) { _, newDistance in
            splitTimesManager.checkForNewSplit(
                distance: newDistance,
                time: workoutManager.elapsedTime,
                speed: locationService.gpsSpeedKmh,
                strokeRate: workoutManager.strokeRate
            )
            // Announce split if audio coach enabled
            if audioCoachManager.splitAnnouncementsEnabled, let lastSplit = splitTimesManager.splits.last {
                audioCoachManager.announceSplit(
                    splitNumber: splitTimesManager.splits.count,
                    pace: lastSplit.formattedPace,
                    distance: "\(lastSplit.distance)m"
                )
            }
        }
        .sheet(isPresented: $showingWorkoutModes) {
            WorkoutModeSelectionView(
                selectedMode: $selectedWorkoutMode,
                selectedBoatType: $selectedBoatType,
                distanceGoal: $distanceGoal,
                timeGoal: $timeGoal,
                intervalWorkout: $intervalWorkout
            )
        }
        .alert(String(localized: "alert.saveWorkout"), isPresented: $showingSaveAlert) {
            Button(String(localized: "button.save")) {
                saveWorkout()
            }
            Button(String(localized: "alert.cancel"), role: .cancel) {}
        } message: {
            Text("alert.saveMessage", tableName: nil, bundle: .main, comment: "")
        }
    }
    
    // MARK: - Workout Tab
    private var workoutTab: some View {
        ZStack {
            // Arka plan gradyanı
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.05, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if requiresLocationPermissionPrompt {
                PermissionView(
                    locationService: locationService,
                    authorizationStatus: locationService.authorizationStatus
                )
            } else {
                workoutContent
            }
        }
    }
    
    private var workoutContent: some View {
        VStack(spacing: 0) {
            // Başlık
            headerView
            
            ScrollView {
                VStack(spacing: 20) {
                    // Ana metrikler
                    mainMetricsView
                    
                    // Detaylı istatistikler
                    detailedStatsView
                    
                    // Kontrol butonları
                    controlButtonsView
                    
                    // Mini harita
                    if showingMap {
                        mapView
                    }
                    
                    // Harita toggle butonu
                    mapToggleButton
                    
                    // Kaydet butonu
                    saveButtonView
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("app.name", tableName: nil, bundle: .main, comment: "")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .cyan.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(workoutManager.isActive ? String(localized: "workout.active") : String(localized: "workout.ready"))
                    .font(.subheadline)
                    .foregroundColor(workoutManager.isActive ? .green : .gray)
            }
            
            Spacer()
            
            // Sesli koç butonu
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    audioCoachManager.isEnabled.toggle()
                    if audioCoachManager.isEnabled && workoutManager.isActive {
                        audioCoachManager.startTempoBeep()
                    } else {
                        audioCoachManager.stopTempoBeep()
                    }
                }
            }) {
                Image(systemName: audioCoachManager.isEnabled ? "speaker.wave.3.fill" : "speaker.slash")
                    .font(.system(size: 22))
                    .foregroundColor(audioCoachManager.isEnabled ? .green : .gray)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Ana Metrikler
    private var mainMetricsView: some View {
        VStack(spacing: 16) {
            // Süre - büyük gösterim
            VStack(spacing: 4) {
                Text("metric.duration", tableName: nil, bundle: .main, comment: "")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan.opacity(0.8))
                
                Text(workoutManager.formattedTime)
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.5), .blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            
            // Hız ve Mesafe - yan yana
            HStack(spacing: 12) {
                MetricCard(
                    title: String(localized: "metric.speed"),
                    value: String(format: "%.1f", locationService.gpsSpeedKmh),
                    unit: String(localized: "unit.kmh"),
                    icon: "speedometer",
                    color: .orange
                )
                
                MetricCard(
                    title: String(localized: "metric.distance"),
                    value: formattedDistanceValue,
                    unit: formattedDistanceUnit,
                    icon: "arrow.left.and.right",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Detaylı İstatistikler
    private var detailedStatsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SmallStatCard(
                    title: String(localized: "metric.avgSpeed"),
                    value: String(format: "%.1f", workoutManager.averageSpeed),
                    unit: String(localized: "unit.kmh"),
                    icon: "gauge.medium"
                )
                
                SmallStatCard(
                    title: String(localized: "metric.maxSpeed"),
                    value: String(format: "%.1f", workoutManager.maxSpeed),
                    unit: String(localized: "unit.kmh"),
                    icon: "gauge.high"
                )
                
                SmallStatCard(
                    title: String(localized: "metric.calories"),
                    value: String(format: "%.0f", workoutManager.calories),
                    unit: String(localized: "unit.kcal"),
                    icon: "flame.fill"
                )
            }
            
            HStack(spacing: 12) {
                SmallStatCard(
                    title: String(localized: "metric.strokeRate"),
                    value: String(format: "%.0f", workoutManager.strokeRate),
                    unit: String(localized: "unit.spm"),
                    icon: "waveform.path"
                )
                
                SmallStatCard(
                    title: String(localized: "metric.totalStrokes"),
                    value: String(format: "%.0f", workoutManager.totalStrokes),
                    unit: "",
                    icon: "number"
                )
                
                SmallStatCard(
                    title: String(localized: "metric.pace"),
                    value: workoutManager.formattedPace,
                    unit: "/500m",
                    icon: "timer"
                )
            }
        }
    }
    
    // MARK: - Kontrol Butonları
    private var controlButtonsView: some View {
        VStack(spacing: 16) {
            // Antrenman modu seçimi
            Button(action: {
                showingWorkoutModes = true
            }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("mode.selectTitle", tableName: nil, bundle: .main, comment: "")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.purple)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.3))
                        .overlay(
                            Capsule()
                                .stroke(.purple.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            HStack(spacing: 20) {
            // Sıfırla butonu
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    workoutManager.reset()
                    locationService.resetDistance()
                    splitTimesManager.reset()
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 24, weight: .semibold))
                    Text("button.reset", tableName: nil, bundle: .main, comment: "")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            Circle()
                                .stroke(.gray.opacity(0.5), lineWidth: 2)
                        )
                )
            }
            
            // Başlat/Durdur butonu
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    if workoutManager.isActive {
                        workoutManager.pause()
                    } else {
                        workoutManager.start()
                    }
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: workoutManager.isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 36, weight: .bold))
                    Text(workoutManager.isActive ? String(localized: "button.stop") : String(localized: "button.start"))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(width: 120, height: 120)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: workoutManager.isActive
                                    ? [.red, .orange]
                                    : [.green, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: workoutManager.isActive ? .red.opacity(0.5) : .green.opacity(0.5),
                            radius: 15,
                            x: 0,
                            y: 5
                        )
                )
            }
            .scaleEffect(workoutManager.isActive ? 1.05 : 1.0)
            
            // Tur butonu
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    workoutManager.addLap()
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 24, weight: .semibold))
                    Text("button.lap", tableName: nil, bundle: .main, comment: "")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(.blue.opacity(0.3))
                        .overlay(
                            Circle()
                                .stroke(.blue.opacity(0.5), lineWidth: 2)
                        )
                )
            }
            } // HStack kapanışı
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Harita
    private var mapView: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.hybrid)
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.cyan.opacity(0.3), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
    }
    
    private var mapToggleButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingMap.toggle()
            }
        }) {
            HStack {
                Image(systemName: showingMap ? "map.fill" : "map")
                Text(showingMap ? String(localized: "button.hideMap") : String(localized: "button.showMap"))
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.cyan)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(.cyan.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Action Buttons
    // MARK: - Save Button
    private var saveButtonView: some View {
        Button(action: {
            showingSaveAlert = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("button.save", tableName: nil, bundle: .main, comment: "")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.green)
            .padding(.horizontal, 30)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(workoutManager.elapsedTime < 10)
        .opacity(workoutManager.elapsedTime < 10 ? 0.5 : 1)
    }
    
    // MARK: - Helpers
    private var formattedDistanceValue: String {
        let meters = locationService.totalDistanceMeters
        if meters < 1000 {
            return String(format: "%.0f", meters)
        } else {
            return String(format: "%.2f", meters / 1000.0)
        }
    }
    
    private var formattedDistanceUnit: String {
        locationService.totalDistanceMeters < 1000 ? "m" : "km"
    }
    
    private var requiresLocationPermissionPrompt: Bool {
        switch locationService.authorizationStatus {
        case .notDetermined, .denied, .restricted:
            return true
        default:
            return false
        }
    }
    
    private func saveWorkout() {
        let lapRecords = workoutManager.laps.map { LapRecord(from: $0) }
        
        let workout = WorkoutRecord(
            duration: workoutManager.elapsedTime,
            distance: locationService.totalDistanceMeters,
            averageSpeed: workoutManager.averageSpeed,
            maxSpeed: workoutManager.maxSpeed,
            calories: workoutManager.calories,
            totalStrokes: workoutManager.totalStrokes,
            laps: lapRecords
        )
        
        historyManager.saveWorkout(workout)
        
        // Antrenmanı sıfırla
        workoutManager.reset()
        locationService.resetDistance()
    }
}

#Preview {
    ContentView()
}
