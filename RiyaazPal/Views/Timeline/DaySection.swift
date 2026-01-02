//
//  SessionRow.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-31.
//

import Foundation

import SwiftUI

struct DaySection: View {
    let date: Date
    let sessions: [PracticeSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            VStack(spacing: 12) {
                ForEach(sessions) { session in
                    SessionCard(session: session)
                }
            }
        }
    }
}

private extension DaySection {

    var header: some View {
        Text(formattedDate)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    DaySection(
        date: Date(),
        sessions: [
            PracticeSession(
                startTime: Date(),
                duration: 45 * 60,
                notes: "Taan practice – drut teentaal",
                tags: ["Raga Puriya", "Taan", "Technical"]
            ),
            PracticeSession(
                startTime: Date(timeIntervalSinceNow: 900),
                duration: 45 * 60,
                notes: "Jod practice",
                tags: ["Raga Puriya", "Jod", "Ragadari"]
            )
        ]
        
    )
    .padding()
}
