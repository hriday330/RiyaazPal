//
//  InsightWindow.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-07.
//

import Foundation

enum InsightWindow {
    static let days: Int = 30
}


struct DateRange {
    let start: Date
    let end: Date

    func contains(_ date: Date) -> Bool {
        date >= start && date <= end
    }
}


enum InsightWindowHelper {

    // Returns the date range covering the insight window ending at `now`.
    static func dateRange(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DateRange {
        let end = now
        let start = calendar.date(
            byAdding: .day,
            value: -InsightWindow.days,
            to: end
        ) ?? end

        return DateRange(start: start, end: end)
    }

    // Filters sessions to only those within the insight window.
    static func sessionsInWindow(
        _ sessions: [PracticeSession],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [PracticeSession] {

        let range = dateRange(now: now, calendar: calendar)

        return sessions.filter { session in
            range.contains(session.startTime)
        }
    }
}
