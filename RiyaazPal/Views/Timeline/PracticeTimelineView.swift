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
        VStack {
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

#Preview {
    PracticeTimelineView()
}
