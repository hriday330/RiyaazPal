//
//  PracticeTimelineView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-29.
//

import SwiftUI

struct PracticeTimelineView: View {
    @StateObject private var viewModel = PracticeTimelineViewModel()
    var body: some View {
            ZStack {
                // App-wide background
                Color("AppBackground")
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(viewModel.sessionsGroupedByDay, id: \.date) { group in
                            DaySection(
                                date: group.date,
                                sessions: group.sessions
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("RiyaazPal")
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
