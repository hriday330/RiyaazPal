#if DEBUG
import Foundation
import SwiftData

enum TestDataSeedScenario: String, CaseIterable, Identifiable {
    case freshUser
    case inconsistentImproving
    case powerUser

    var id: String { rawValue }

    var title: String {
        switch self {
        case .freshUser:
            return "Fresh User"
        case .inconsistentImproving:
            return "Inconsistent Improving User"
        case .powerUser:
            return "Power User"
        }
    }
}

enum TestDataSeeder {

    enum SeedError: LocalizedError {
        case iCloudSyncEnabled

        var errorDescription: String? {
            switch self {
            case .iCloudSyncEnabled:
                return "Turn off iCloud sync and restart RiyaazPal before seeding local test data."
            }
        }
    }

    static func seed(
        _ scenario: TestDataSeedScenario,
        context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws {
        guard UserDefaults.standard.object(forKey: RiyaazPalModelContainer.iCloudSyncEnabledKey) as? Bool == false else {
            throw SeedError.iCloudSyncEnabled
        }

        try clear(context: context)
        try context.save()

        switch scenario {
        case .freshUser:
            break
        case .inconsistentImproving:
            seedInconsistentImprovingUser(context: context, now: now, calendar: calendar)
        case .powerUser:
            seedPowerUser(context: context, now: now, calendar: calendar)
        }

        try context.save()
    }
}

private extension TestDataSeeder {

    static func clear(context: ModelContext) throws {
        let ratings = try context.fetch(FetchDescriptor<PracticeAreaRatingEntity>())
        let sessions = try context.fetch(FetchDescriptor<PracticeSession>())
        let practiceAreas = try context.fetch(FetchDescriptor<PracticeAreaEntity>())

        for rating in ratings {
            context.delete(rating)
        }

        for session in sessions {
            context.delete(session)
        }

        for area in practiceAreas {
            context.delete(area)
        }
    }

    static func seedInconsistentImprovingUser(
        context: ModelContext,
        now: Date,
        calendar: Calendar
    ) {
        let areas = insertAreas(
            ["Alaap", "Sapat Taans", "Layakari", "Bol Taans"],
            context: context,
            now: now,
            calendar: calendar
        )

        let sparsePracticeDays = [-27, -22, -16, -10, -6, -2]

        for (index, dayOffset) in sparsePracticeDays.enumerated() {
            let score = min(8, 4 + index)
            insertSession(
                dayOffset: dayOffset,
                durationMinutes: 42,
                notes: "Seeded practice",
                sessionType: .practice,
                context: context,
                areas: areas,
                scores: [
                    "Alaap": score,
                    "Sapat Taans": max(5, score - 1),
                    "Layakari": index.isMultiple(of: 2) ? 6 : 7
                ],
                now: now,
                calendar: calendar
            )
        }
    }

    static func seedPowerUser(
        context: ModelContext,
        now: Date,
        calendar: Calendar
    ) {
        let areas = insertAreas(
            ["Alaap", "Sapat Taans", "Layakari", "Bol Taans", "Meend"],
            context: context,
            now: now,
            calendar: calendar
        )

        for index in 0..<1000 {
            let dayOffset = -360 + (index / 3)
            let sessionType: SessionType = index.isMultiple(of: 13) ? .concert : .practice
            let scores = baselineScores(for: index, sessionType: sessionType)

            insertSession(
                dayOffset: dayOffset,
                durationMinutes: sessionType == .concert ? 90 : 55,
                notes: sessionType == .concert ? "Seeded concert" : "Seeded practice",
                sessionType: sessionType,
                context: context,
                areas: areas,
                scores: scores,
                now: now,
                calendar: calendar
            )
        }

        seedPowerUserSignals(
            context: context,
            areas: areas,
            now: now,
            calendar: calendar
        )
    }

    static func seedPowerUserSignals(
        context: ModelContext,
        areas: [String: PracticeAreaEntity],
        now: Date,
        calendar: Calendar
    ) {
        let previousWindowDays = [-13, -12, -11, -10, -9, -8]
        let recentWindowDays = [-6, -5, -4, -3, -2, -1]

        for dayOffset in previousWindowDays {
            insertSession(
                dayOffset: dayOffset,
                durationMinutes: 60,
                notes: "Seeded previous trend window",
                sessionType: .practice,
                context: context,
                areas: areas,
                scores: [
                    "Alaap": 5,
                    "Sapat Taans": 8,
                    "Layakari": 7,
                    "Bol Taans": 8
                ],
                now: now,
                calendar: calendar
            )
        }

        for dayOffset in recentWindowDays {
            insertSession(
                dayOffset: dayOffset,
                durationMinutes: 60,
                notes: "Seeded recent trend window",
                sessionType: .practice,
                context: context,
                areas: areas,
                scores: [
                    "Alaap": 8,
                    "Sapat Taans": 5,
                    "Layakari": 7,
                    "Bol Taans": 9
                ],
                now: now,
                calendar: calendar
            )
        }

        for dayOffset in [-6, -4, -2] {
            insertSession(
                dayOffset: dayOffset,
                durationMinutes: 85,
                notes: "Seeded concert drop",
                sessionType: .concert,
                context: context,
                areas: areas,
                scores: [
                    "Alaap": 7,
                    "Sapat Taans": 6,
                    "Layakari": 7,
                    "Bol Taans": 5
                ],
                now: now,
                calendar: calendar
            )
        }

        insertSession(
            dayOffset: -14,
            durationMinutes: 45,
            notes: "Seeded neglected area",
            sessionType: .practice,
            context: context,
            areas: areas,
            scores: [
                "Meend": 6
            ],
            now: now,
            calendar: calendar
        )
    }

    static func insertAreas(
        _ names: [String],
        context: ModelContext,
        now: Date,
        calendar: Calendar
    ) -> [String: PracticeAreaEntity] {
        var areas: [String: PracticeAreaEntity] = [:]

        for (index, name) in names.enumerated() {
            let area = PracticeAreaEntity(
                name: name,
                createdAt: calendar.date(byAdding: .day, value: -120, to: now) ?? now,
                isActive: true,
                order: index
            )

            context.insert(area)
            areas[name] = area
        }

        return areas
    }

    static func insertSession(
        dayOffset: Int,
        durationMinutes: Int,
        notes: String,
        sessionType: SessionType,
        context: ModelContext,
        areas: [String: PracticeAreaEntity],
        scores: [String: Int],
        now: Date,
        calendar: Calendar
    ) {
        let startTime = sessionDate(dayOffset: dayOffset, now: now, calendar: calendar)
        let session = PracticeSession(
            startTime: startTime,
            duration: TimeInterval(durationMinutes * 60),
            notes: notes,
            tags: [],
            detailedNotes: "",
            lastModified: startTime,
            sessionType: sessionType,
            confidence: sessionType == .concert ? 6 : 5
        )

        context.insert(session)

        for (name, score) in scores {
            guard let area = areas[name] else { continue }

            let rating = PracticeAreaRatingEntity(
                sessionID: session.id,
                practiceAreaID: area.id,
                areaName: area.name,
                didPractice: true,
                score: score,
                createdAt: startTime,
                lastModified: startTime
            )

            context.insert(rating)
        }
    }

    static func baselineScores(
        for index: Int,
        sessionType: SessionType
    ) -> [String: Int] {
        let variation = index % 3

        if sessionType == .concert {
            return [
                "Alaap": 7,
                "Sapat Taans": 6 + variation,
                "Layakari": 7,
                "Bol Taans": 5
            ]
        }

        return [
            "Alaap": 6 + variation,
            "Sapat Taans": 7,
            "Layakari": 7,
            "Bol Taans": 8
        ]
    }

    static func sessionDate(
        dayOffset: Int,
        now: Date,
        calendar: Calendar
    ) -> Date {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
        let hour = 9 + abs(dayOffset % 8)
        return calendar.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: day
        ) ?? day
    }
}
#endif
