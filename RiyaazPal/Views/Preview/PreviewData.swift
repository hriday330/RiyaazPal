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

    static func insertPerfectSessions(into context: ModelContext) {
        let now = Date()

        let sessions: [PracticeSession] = [
            // Day 1 – balanced, moderate
            PracticeSession(
                startTime: now.addingTimeInterval(-1 * 24 * 60 * 60),
                duration: 60 * 60,
                notes: "Balanced riyaz – alap, vilambit, laya",
                tags: ["alap", "gat", "layakari"]
            ),

            // Day 2 – same structure (stability)
            PracticeSession(
                startTime: now.addingTimeInterval(-2 * 24 * 60 * 60),
                duration: 55 * 60,
                notes: "Steady practice with laya focus",
                tags: ["alap", "gat", "layakari"]
            ),

            // Day 3 – technique integrated, not isolated
            PracticeSession(
                startTime: now.addingTimeInterval(-3 * 24 * 60 * 60),
                duration: 65 * 60,
                notes: "Integrated taans within vilambit",
                tags: ["alap", "gat", "layakari", "taans"]
            ),

            // Day 4 – slightly shorter, still complete
            PracticeSession(
                startTime: now.addingTimeInterval(-4 * 24 * 60 * 60),
                duration: 45 * 60,
                notes: "Shorter but complete session",
                tags: ["alap", "gat", "layakari"]
            ),

            // Day 5 – slightly longer, no fatigue pairing
            PracticeSession(
                startTime: now.addingTimeInterval(-5 * 24 * 60 * 60),
                duration: 70 * 60,
                notes: "Extended vilambit work with layakari",
                tags: ["alap", "gat", "layakari"]
            ),

            // Day 6 – moderate, consistent
            PracticeSession(
                startTime: now.addingTimeInterval(-6 * 24 * 60 * 60),
                duration: 50 * 60,
                notes: "Consistent daily riyaz",
                tags: ["alap", "gat", "layakari"]
            ),

            // Day 7 – rest day or no session (intentionally omitted)

            // Older session (outside window)
            PracticeSession(
                startTime: now.addingTimeInterval(-9 * 24 * 60 * 60),
                duration: 60 * 60,
                notes: "Older reference session",
                tags: ["alap", "gat", "layakari"]
            )
        ]

        for session in sessions {
            context.insert(session)
        }
    }
    
    static func insertPerfectMonth(into context: ModelContext) {
        let now = Date()

        let baseTags = ["alap", "gat", "layakari"]
        let optionalTechnique = "taans"

        for dayOffset in 1...28 {
            let duration: TimeInterval

            // Gentle variation, no fatigue patterns
            switch dayOffset % 4 {
            case 0:
                duration = 45 * 60
            case 1:
                duration = 55 * 60
            case 2:
                duration = 60 * 60
            default:
                duration = 50 * 60
            }

            var tags = baseTags

            // Light technique integration 2x a week
            if dayOffset % 7 == 0 || dayOffset % 7 == 3 {
                tags.append(optionalTechnique)
            }

            let session = PracticeSession(
                startTime: now.addingTimeInterval(
                    -Double(dayOffset) * 24 * 60 * 60
                ),
                duration: duration,
                notes: "Consistent daily riyaz",
                tags: tags
            )

            context.insert(session)
        }
    }

}
