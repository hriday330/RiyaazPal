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
                floatingSessionButton
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
                        systemImage: sessionViewModel.isSessionActive ? "stop.fill" : "play.fil"
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
