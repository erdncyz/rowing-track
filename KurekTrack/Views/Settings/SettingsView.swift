//
//  SettingsView.swift
//  KurekTrack
//
//  Uygulama ayarları ve dil seçimi
//

import SwiftUI
import Combine

// MARK: - App Language
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case turkish = "tr"
    case english = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return String(localized: "settings.language.system")
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }
    
    var flag: String {
        switch self {
        case .system: return "🌐"
        case .turkish: return "🇹🇷"
        case .english: return "🇬🇧"
        }
    }
}

// MARK: - Settings Manager
@MainActor
final class SettingsManager: ObservableObject {
    @Published var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "appLanguage")
            applyLanguage()
        }
    }
    
    @Published var useMetricUnits: Bool {
        didSet {
            UserDefaults.standard.set(useMetricUnits, forKey: "useMetricUnits")
        }
    }
    
    @Published var hapticFeedback: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedback, forKey: "hapticFeedback")
        }
    }
    
    @Published var keepScreenOn: Bool {
        didSet {
            UserDefaults.standard.set(keepScreenOn, forKey: "keepScreenOn")
            UIApplication.shared.isIdleTimerDisabled = keepScreenOn
        }
    }
    
    init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        self.selectedLanguage = AppLanguage(rawValue: savedLanguage) ?? .system
        self.useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
        self.hapticFeedback = UserDefaults.standard.object(forKey: "hapticFeedback") as? Bool ?? true
        self.keepScreenOn = UserDefaults.standard.object(forKey: "keepScreenOn") as? Bool ?? true
        
        // Ekran açık kalması
        UIApplication.shared.isIdleTimerDisabled = keepScreenOn
    }
    
    func applyLanguage() {
        // Sistem dışı bir dil seçildiyse, uygulamayı o dilde göster
        if selectedLanguage != .system {
            UserDefaults.standard.set([selectedLanguage.rawValue], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
        
        // Kullanıcıya uygulamayı yeniden başlatması gerektiğini bildir
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showLanguageChangeAlert = false
    
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
                        // Dil seçimi
                        languageSection
                        
                        // Birim seçimi
                        unitsSection
                        
                        // Genel ayarlar
                        generalSection
                        
                        // Uygulama bilgisi
                        aboutSection
                    }
                    .padding()
                }
            }
            .navigationTitle(String(localized: "settings.title"))
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
        .alert(String(localized: "settings.language.restartTitle"), isPresented: $showLanguageChangeAlert) {
            Button(String(localized: "alert.ok")) {}
        } message: {
            Text("settings.language.restartMessage", tableName: nil, bundle: .main, comment: "")
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            showLanguageChangeAlert = true
        }
    }
    
    // MARK: - Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.cyan)
                
                Text("settings.language", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                ForEach(AppLanguage.allCases) { language in
                    LanguageRow(
                        language: language,
                        isSelected: settingsManager.selectedLanguage == language,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                settingsManager.selectedLanguage = language
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Units Section
    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "ruler")
                    .foregroundColor(.orange)
                
                Text("settings.units", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("settings.useMetric", tableName: nil, bundle: .main, comment: "")
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $settingsManager.useMetricUnits)
                    .labelsHidden()
                    .tint(.orange)
            }
            
            Text(settingsManager.useMetricUnits ? 
                 String(localized: "settings.metric.description") : 
                 String(localized: "settings.imperial.description"))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - General Section
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.purple)
                
                Text("settings.general", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Ekran açık kalması
            HStack {
                VStack(alignment: .leading) {
                    Text("settings.keepScreenOn", tableName: nil, bundle: .main, comment: "")
                        .foregroundColor(.white)
                    Text("settings.keepScreenOn.description", tableName: nil, bundle: .main, comment: "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: $settingsManager.keepScreenOn)
                    .labelsHidden()
                    .tint(.purple)
            }
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Titreşim geri bildirimi
            HStack {
                VStack(alignment: .leading) {
                    Text("settings.hapticFeedback", tableName: nil, bundle: .main, comment: "")
                        .foregroundColor(.white)
                    Text("settings.hapticFeedback.description", tableName: nil, bundle: .main, comment: "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: $settingsManager.hapticFeedback)
                    .labelsHidden()
                    .tint(.purple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.green)
                
                Text("settings.about", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("settings.version", tableName: nil, bundle: .main, comment: "")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("settings.build", tableName: nil, bundle: .main, comment: "")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("1")
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Language Row
struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.flag)
                    .font(.title2)
                
                Text(language.displayName)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.cyan)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.cyan.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
}
