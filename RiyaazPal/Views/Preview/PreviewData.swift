//
//  PreviewData.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-03.
//

import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static func insertSessions(into context: ModelContext) {
        let now = Date()
        let sessions: [PracticeSession] = [
            // Yesterday – long session (sets up fatigue signal)
            PracticeSession(
                startTime: now.addingTimeInterval(-1 * 24 * 60 * 60),
                duration: 75 * 60,
                notes: "Evening riyaz – vilambit alap",
                tags: ["vilambit", "alap"]
            ),

            // Today – short follow-up (fatigue)
            PracticeSession(
                startTime: now.addingTimeInterval(-0.5 * 24 * 60 * 60),
                duration: 25 * 60,
                notes: "Short maintenance session",
                tags: ["drut", "taans"]
            ),

            // 2 days ago – technique-heavy
            PracticeSession(
                startTime: now.addingTimeInterval(-2 * 24 * 60 * 60),
                duration: 40 * 60,
                notes: "Taans and bol patterns",
                tags: ["taans"]
            ),

            // 3 days ago – long, but different focus (volatility)
            PracticeSession(
                startTime: now.addingTimeInterval(-3 * 24 * 60 * 60),
                duration: 90 * 60,
                notes: "Extended practice, explored new material",
                tags: ["drut", "gat"]
            ),

            // 4 days ago – alap only
            PracticeSession(
                startTime: now.addingTimeInterval(-4 * 24 * 60 * 60),
                duration: 30 * 60,
                notes: "Slow alap exploration",
                tags: ["alap"]
            ),

            // 5 days ago – vilambit without laya
            PracticeSession(
                startTime: now.addingTimeInterval(-5 * 24 * 60 * 60),
                duration: 50 * 60,
                notes: "Vilambit phrases",
                tags: ["alap"]
            ),

            // 6 days ago – warm-up only
            PracticeSession(
                startTime: now.addingTimeInterval(-6 * 24 * 60 * 60),
                duration: 20 * 60,
                notes: "Quick warm-up",
                tags: ["alap"]
            ),

            // 8 days ago – outside recent window (ignored by Insights)
            PracticeSession(
                startTime: now.addingTimeInterval(-8 * 24 * 60 * 60),
                duration: 60 * 60,
                notes: "Older session",
                tags: ["vilambit", "alap", "layakari"]
            )
        ]


        for session in sessions {
            context.insert(session)
        }

    }
}
