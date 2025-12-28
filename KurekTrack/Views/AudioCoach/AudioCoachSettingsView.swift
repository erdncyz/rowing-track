//
//  AudioCoach.swift
//  KurekTrack
//
//  Sesli koçluk ve tempo yönetimi
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

// MARK: - Audio Coach Manager
@MainActor
final class AudioCoachManager: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var tempoBeepEnabled: Bool = true
    @Published var splitAnnouncementsEnabled: Bool = true
    @Published var motivationEnabled: Bool = true
    @Published var targetStrokeRate: Double = 24  // Hedef SPM
    
    private var synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var tempoTimer: Timer?
    private var lastMotivationTime: Date = .distantPast
    
    // Tempo aralığı (saniye)
    var tempoInterval: TimeInterval {
        60.0 / targetStrokeRate
    }
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioCoach] Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Tempo Beep
    func startTempoBeep() {
        guard tempoBeepEnabled && isEnabled else { return }
        
        stopTempoBeep()
        
        let interval = tempoInterval
        tempoTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.playBeep()
            }
        }
        
        print("[AudioCoach] Tempo started at \(targetStrokeRate) SPM")
    }
    
    func stopTempoBeep() {
        tempoTimer?.invalidate()
        tempoTimer = nil
    }
    
    func updateTempo(_ newRate: Double) {
        targetStrokeRate = newRate
        if tempoTimer != nil {
            startTempoBeep() // Restart with new tempo
        }
    }
    
    private func playBeep() {
        AudioServicesPlaySystemSound(1104) // Tock sound
    }
    
    // MARK: - Speech Announcements
    func announceSplit(splitNumber: Int, pace: String, distance: String) {
        guard splitAnnouncementsEnabled && isEnabled else { return }
        
        let message = String(localized: "coach.splitAnnouncement \(splitNumber) \(pace) \(distance)")
        speak(message)
    }
    
    func announceWorkoutStart() {
        guard isEnabled else { return }
        speak(String(localized: "coach.workoutStart"))
    }
    
    func announceWorkoutPause() {
        guard isEnabled else { return }
        speak(String(localized: "coach.workoutPause"))
    }
    
    func announceWorkoutComplete(duration: String, distance: String) {
        guard isEnabled else { return }
        let message = String(localized: "coach.workoutComplete \(duration) \(distance)")
        speak(message)
    }
    
    func announceGoalReached(goalType: String) {
        guard isEnabled else { return }
        let message = String(localized: "coach.goalReached \(goalType)")
        speak(message)
    }
    
    // MARK: - Motivation
    func checkForMotivation(currentSpeed: Double, averageSpeed: Double, elapsedTime: TimeInterval) {
        guard motivationEnabled && isEnabled else { return }
        
        // Her 5 dakikada bir motivasyon
        let timeSinceLastMotivation = Date().timeIntervalSince(lastMotivationTime)
        guard timeSinceLastMotivation > 300 else { return }
        
        var message: String?
        
        if currentSpeed > averageSpeed * 1.1 {
            // Ortalamadan %10 hızlı
            message = motivationalMessages.fast.randomElement()
        } else if currentSpeed < averageSpeed * 0.9 && currentSpeed > 0 {
            // Ortalamadan %10 yavaş
            message = motivationalMessages.slow.randomElement()
        } else if elapsedTime > 600 && elapsedTime < 610 {
            // 10 dakika geçti
            message = motivationalMessages.milestone10.randomElement()
        } else if elapsedTime > 1800 && elapsedTime < 1810 {
            // 30 dakika geçti
            message = motivationalMessages.milestone30.randomElement()
        }
        
        if let msg = message {
            speak(msg)
            lastMotivationTime = Date()
        }
    }
    
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier == "tr" ? "tr-TR" : "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        stopTempoBeep()
    }
    
    // MARK: - Motivational Messages
    private let motivationalMessages = (
        fast: [
            String(localized: "coach.motivation.fast1"),
            String(localized: "coach.motivation.fast2"),
            String(localized: "coach.motivation.fast3"),
        ],
        slow: [
            String(localized: "coach.motivation.slow1"),
            String(localized: "coach.motivation.slow2"),
            String(localized: "coach.motivation.slow3"),
        ],
        milestone10: [
            String(localized: "coach.motivation.10min1"),
            String(localized: "coach.motivation.10min2"),
        ],
        milestone30: [
            String(localized: "coach.motivation.30min1"),
            String(localized: "coach.motivation.30min2"),
        ]
    )
}

// MARK: - Audio Coach Settings View
struct AudioCoachSettingsView: View {
    @ObservedObject var audioCoach: AudioCoachManager
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
                        // Ana toggle
                        mainToggleCard
                        
                        if audioCoach.isEnabled {
                            // Tempo ayarları
                            tempoSettingsCard
                            
                            // Duyuru ayarları
                            announcementSettingsCard
                            
                            // Motivasyon ayarları
                            motivationSettingsCard
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(String(localized: "coach.title"))
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
    
    private var mainToggleCard: some View {
        HStack {
            Image(systemName: "speaker.wave.3.fill")
                .font(.title)
                .foregroundColor(audioCoach.isEnabled ? .cyan : .gray)
            
            VStack(alignment: .leading) {
                Text("coach.audioCoach", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("coach.audioCoachDesc", tableName: nil, bundle: .main, comment: "")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $audioCoach.isEnabled)
                .labelsHidden()
                .tint(.cyan)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(audioCoach.isEnabled ? .cyan.opacity(0.3) : .white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var tempoSettingsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("coach.tempoBeep", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $audioCoach.tempoBeepEnabled)
                    .labelsHidden()
                    .tint(.cyan)
            }
            
            if audioCoach.tempoBeepEnabled {
                VStack(spacing: 8) {
                    HStack {
                        Text("coach.targetSPM", tableName: nil, bundle: .main, comment: "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(Int(audioCoach.targetStrokeRate)) SPM")
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }
                    
                    Slider(value: $audioCoach.targetStrokeRate, in: 16...40, step: 1)
                        .tint(.cyan)
                    
                    HStack {
                        Text("16")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("40")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Tempo önerileri
                HStack(spacing: 8) {
                    TempoPresetButton(title: "Easy", spm: 20, selectedSPM: $audioCoach.targetStrokeRate)
                    TempoPresetButton(title: "Steady", spm: 24, selectedSPM: $audioCoach.targetStrokeRate)
                    TempoPresetButton(title: "Race", spm: 32, selectedSPM: $audioCoach.targetStrokeRate)
                    TempoPresetButton(title: "Sprint", spm: 38, selectedSPM: $audioCoach.targetStrokeRate)
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
    
    private var announcementSettingsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.orange)
                
                Text("coach.splitAnnouncements", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $audioCoach.splitAnnouncementsEnabled)
                    .labelsHidden()
                    .tint(.orange)
            }
            
            Text("coach.splitAnnouncementsDesc", tableName: nil, bundle: .main, comment: "")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private var motivationSettingsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                
                Text("coach.motivation", tableName: nil, bundle: .main, comment: "")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $audioCoach.motivationEnabled)
                    .labelsHidden()
                    .tint(.red)
            }
            
            Text("coach.motivationDesc", tableName: nil, bundle: .main, comment: "")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
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
}

struct TempoPresetButton: View {
    let title: String
    let spm: Double
    @Binding var selectedSPM: Double
    
    var isSelected: Bool {
        selectedSPM == spm
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedSPM = spm
            }
        }) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                Text("\(Int(spm))")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? .cyan.opacity(0.3) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? .cyan : .gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    AudioCoachSettingsView(audioCoach: AudioCoachManager())
}
