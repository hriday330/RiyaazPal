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
        context.insert(
            PracticeSession(
                startTime: Date(),
                duration: 1800,
                notes: "Alap practice"
            )
        )

        context.insert(
            PracticeSession(
                startTime: Date().addingTimeInterval(-86400),
                duration: 2400,
                notes: "Jod + Jhala",
                tags: ["riyaz"]
            )
        )
    }
}
