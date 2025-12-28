//
//  SmallStatCard.swift
//  KurekTrack
//

import SwiftUI

struct SmallStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cyan)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.2))
        )
    }
}

#Preview {
    SmallStatCard(
        title: "Avg Speed",
        value: "10.2",
        unit: "km/h",
        icon: "speedometer"
    )
    .padding()
    .background(.black)
}
