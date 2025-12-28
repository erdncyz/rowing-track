//
//  PermissionView.swift
//  KurekTrack
//

import SwiftUI
import CoreLocation

struct PermissionView: View {
    let locationService: LocationService
    let authorizationStatus: CLAuthorizationStatus
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "figure.outdoor.rowing")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text("app.name", tableName: nil, bundle: .main, comment: "")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                Text("permission.title", tableName: nil, bundle: .main, comment: "")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("permission.message", tableName: nil, bundle: .main, comment: "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                if authorizationStatus == .notDetermined {
                    locationService.requestAuthorization()
                } else {
                    openSettings()
                }
            }) {
                Text(authorizationStatus == .notDetermined ? String(localized: "permission.allow") : String(localized: "permission.openSettings"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    PermissionView(
        locationService: LocationService(),
        authorizationStatus: .notDetermined
    )
}
