//
//  PracticeTimelineView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-29.
//

import SwiftUI

struct PracticeTimelineView: View {
    @StateObject private var timelineViewModel = PracticeTimelineViewModel()
    
    @StateObject private var sessionViewModel = PracticeSessionViewModel()
    
    
    var body: some View {
            ZStack {
                // App-wide background
                Color("AppBackground")
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(timelineViewModel.sessionsGroupedByDay, id: \.date) { group in
                            DaySection(
                                date: group.date,
                                sessions: group.sessions
                            )
                        }
                    }
                    .padding()
                }
                sessionControl
            }
            .navigationTitle("RiyaazPal")
        }
}

private extension PracticeTimelineView {
    func handleSessionAction() {
            if sessionViewModel.isSessionActive {
                if let session = sessionViewModel.endSession() {
                    timelineViewModel.addSession(session)
                }
            } else {
                sessionViewModel.startSession()
            }
        }
    
    var formattedElapsedTime: String {
        let minutes = Int(sessionViewModel.elapsedTime) / 60
        let seconds = Int(sessionViewModel.elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    
    var sessionControl: some View {
        Group {
            if sessionViewModel.isSessionActive {
                activeSessionBar
            } else {
                floatingSessionButton
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85),
                   value: sessionViewModel.isSessionActive)
    }
    
    var floatingSessionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    handleSessionAction()
                } label : {
                    Label(
                        sessionViewModel.isSessionActive ? "End Session" : "Start Session",
                        systemImage: sessionViewModel.isSessionActive ? "stop.fill" : "play.fill"
                    )
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentColor"))
                .clipShape(Capsule())
                .shadow(radius: 8)
                .padding()
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: sessionViewModel.isSessionActive)
            }
        }
    }
    
    var activeSessionBar: some View {
        VStack {
            Spacer()

            Button {
                handleSessionAction()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(Color("AccentColor"))

                    Text(formattedElapsedTime)
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryText"))

                    Spacer()

                    Text("Recording")
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("ActiveCardBackground"))
                )
                .shadow(radius: 6)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }.transition(.move(edge: .bottom).combined(with: .opacity))
    }

}
#Preview("Light Mode") {
    PracticeTimelineView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    NavigationStack {
            PracticeTimelineView()
        }
        .preferredColorScheme(.dark)
}
