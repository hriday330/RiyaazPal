//
//  ConsistencyStats.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-08.
//

import Foundation

struct ConsistencyStats {
    let practicedDays: Int
    let totalDays: Int
    let streak: Int
}

enum ConsistencyStatsCalculator {

    static func compute(
        sessions: [PracticeSession],
        dateRange: DateRange,
        calendar: Calendar = .current
    ) -> ConsistencyStats {

        let practicedDays = uniquePracticeDays(
            sessions: sessions,
            calendar: calendar,
            dateRange: dateRange
        )

        let totalDays = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: dateRange.start),
            to: calendar.startOfDay(for: dateRange.end)
        ).day ?? 0 + 1

        let streak = currentStreak(
            practicedDays: practicedDays,
            calendar: calendar,
            dateRange: dateRange
        )

        return ConsistencyStats(
            practicedDays: practicedDays.count,
            totalDays: totalDays,
            streak: streak
        )
    }
}

private extension ConsistencyStatsCalculator {

    static func uniquePracticeDays(
        sessions: [PracticeSession],
        calendar: Calendar,
        dateRange: DateRange
    ) -> Set<Date> {
        let windowStart = calendar.startOfDay(for: dateRange.start)
        let windowEnd = calendar.startOfDay(for: dateRange.end)

        return Set(
            sessions.map {
                calendar.startOfDay(for: $0.startTime)
            }.filter { $0 >= windowStart && $0 <= windowEnd}
        )
    }

    static func currentStreak(
        practicedDays: Set<Date>,
        calendar: Calendar,
        dateRange: DateRange
    ) -> Int {

        var streak = 0
        var cursor = calendar.startOfDay(for: Date())

        let windowStart = calendar.startOfDay(for: dateRange.start)
        while cursor >= windowStart && practicedDays.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }

        return streak
    }
}
