//
//  PracticeTimelineEmptyState.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-16.
//

import Foundation
import SwiftUI

struct PracticeTimelineEmptyState<ActiveContent: View>: View {

    let isSessionActive: Bool
    let onStartSession: () -> Void

    @ViewBuilder let activeContent: () -> ActiveContent

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .opacity(0.7)

            VStack(spacing: 6) {
                Text("No practice sessions yet")
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryText"))

                Text("Start a session to track your riyaaz and build a consistent practice habit.")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Group {
                if isSessionActive {
                    activeContent()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button(action: onStartSession) {
                        Label("Start Practice", systemImage: "play.fill")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AccentColor"))
                    .clipShape(Capsule())
                    .transition(.opacity)
                }
            }
            .animation(
                .spring(response: 0.35, dampingFraction: 0.85),
                value: isSessionActive
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }
}
