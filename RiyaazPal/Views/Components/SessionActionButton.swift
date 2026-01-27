//
//  FloatingSessionButton.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-18.
//

import Foundation
import SwiftUI

struct SessionActionButton: View {
    let isActive: Bool
    let action: () -> Void
    let secondaryAction: () -> Void
    
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Label(
                        isActive ? "End Session" : "Start Session",
                        systemImage: isActive ? "stop.fill" : "play.fill"
                    )
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .contextMenu {
                    Button("Log Session", systemImage: "calendar.badge.plus") {
                        secondaryAction()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentColor"))
                .clipShape(Capsule())
                .shadow(radius: 8)
                .padding()
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isActive)
            }
        }
    }
}
