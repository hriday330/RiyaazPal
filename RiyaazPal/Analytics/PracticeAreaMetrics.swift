//
//  PracticeAreaMetrics.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-05-04.
//

import Foundation

struct PracticeAreaMetric: Identifiable {
    let id: String
    let areaID: UUID?
    let areaName: String
    let isActive: Bool

    let latestScore: Int?
    let sevenDayAverage: Double?
    let previousSevenDayAverage: Double?
    let thirtyDayAverage: Double?
    let trendDirection: PracticeAreaTrendDirection

    let ratedSessionCount: Int
    let daysSincePracticed: Int?
    let isNeglected: Bool
    let volatility: Double?

    let practice: PracticeAreaContextMetric
    let concert: PracticeAreaContextMetric
    let scoreHistory: [PracticeAreaScorePoint]
    let performanceTransfer: PracticeAreaPerformanceTransfer

    init(
        id: String,
        areaID: UUID?,
        areaName: String,
        isActive: Bool,
        latestScore: Int?,
        sevenDayAverage: Double?,
        previousSevenDayAverage: Double?,
        thirtyDayAverage: Double?,
        trendDirection: PracticeAreaTrendDirection,
        ratedSessionCount: Int,
        daysSincePracticed: Int?,
        isNeglected: Bool,
        volatility: Double?,
        practice: PracticeAreaContextMetric,
        concert: PracticeAreaContextMetric,
        scoreHistory: [PracticeAreaScorePoint] = [],
        performanceTransfer: PracticeAreaPerformanceTransfer
    ) {
        self.id = id
        self.areaID = areaID
        self.areaName = areaName
        self.isActive = isActive
        self.latestScore = latestScore
        self.sevenDayAverage = sevenDayAverage
        self.previousSevenDayAverage = previousSevenDayAverage
        self.thirtyDayAverage = thirtyDayAverage
        self.trendDirection = trendDirection
        self.ratedSessionCount = ratedSessionCount
        self.daysSincePracticed = daysSincePracticed
        self.isNeglected = isNeglected
        self.volatility = volatility
        self.practice = practice
        self.concert = concert
        self.scoreHistory = scoreHistory
        self.performanceTransfer = performanceTransfer
    }
}

struct PracticeAreaScorePoint: Identifiable {
    let id: UUID
    let date: Date
    let score: Int
    let sessionType: SessionType
}

struct PracticeAreaContextMetric {
    let latestScore: Int?
    let averageScore: Double?
    let ratedSessionCount: Int
    let volatility: Double?
}

struct PracticeAreaPerformanceTransfer {
    let practiceAverage: Double?
    let concertAverage: Double?
    let delta: Double?
    let status: PracticeAreaPerformanceTransferStatus
}

struct PracticeAreaMetricAreaInput: Sendable {
    let id: UUID
    let name: String
    let isActive: Bool
    let order: Int
}

struct PracticeAreaMetricRatingInput: Sendable {
    let sessionID: UUID
    let practiceAreaID: UUID
    let areaName: String
    let didPractice: Bool
    let score: Int?
    let createdAt: Date
    let lastModified: Date
}

struct PracticeAreaMetricSessionInput: Sendable {
    let id: UUID
    let startTime: Date
    let duration: TimeInterval
    let sessionType: SessionType
    let lastModified: Date
}

struct PracticeRhythmMetric {
    let days: [PracticeRhythmDay]
    let practicedDays: Int
    let currentStreak: Int
    let bestWeekPracticedDays: Int
    let totalMinutes: Int

    var averageMinutesPerPracticedDay: Int? {
        guard practicedDays > 0 else { return nil }
        return Int((Double(totalMinutes) / Double(practicedDays)).rounded())
    }
}

struct PracticeRhythmDay: Identifiable {
    let id: Date
    let date: Date
    let practiceMinutes: Int

    var didPractice: Bool {
        practiceMinutes > 0
    }
}

enum PracticeAreaTrendDirection: Equatable {
    case improving
    case declining
    case stable
    case insufficientData
}

enum PracticeAreaPerformanceTransferStatus: Equatable {
    case significantDrop
    case concertLift
    case maintained
    case inconclusive
    case insufficientData
}

enum PracticeAreaMetricsCalculator {

    static let neglectThresholdDays = 5
    static let minimumPracticeScoresForTransfer = 4
    static let minimumConcertScoresForTransfer = 3
    static let significantDropDelta = -1.5
    static let concertLiftDelta = 1.5
    static let maintainedDeltaMagnitude = 1.5

    static func compute(
        practiceAreas: [PracticeAreaEntity],
        ratings: [PracticeAreaRatingEntity],
        sessions: [PracticeSession],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [PracticeAreaMetric] {
        compute(
            practiceAreas: practiceAreas.map {
                PracticeAreaMetricAreaInput(
                    id: $0.id,
                    name: $0.name,
                    isActive: $0.isActive,
                    order: $0.order
                )
            },
            ratings: ratings.map {
                PracticeAreaMetricRatingInput(
                    sessionID: $0.sessionID,
                    practiceAreaID: $0.practiceAreaID,
                    areaName: $0.areaName,
                    didPractice: $0.didPractice,
                    score: $0.score,
                    createdAt: $0.createdAt,
                    lastModified: $0.lastModified
                )
            },
            sessions: sessions.map {
                PracticeAreaMetricSessionInput(
                    id: $0.id,
                    startTime: $0.startTime,
                    duration: $0.duration,
                    sessionType: $0.resolvedSessionType,
                    lastModified: $0.lastModified
                )
            },
            now: now,
            calendar: calendar
        )
    }

    static func compute(
        practiceAreas: [PracticeAreaMetricAreaInput],
        ratings: [PracticeAreaMetricRatingInput],
        sessions: [PracticeAreaMetricSessionInput],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [PracticeAreaMetric] {

        let sessionByID = Dictionary(
            sessions.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let scoredEntries = deduplicatedEntries(ratings.compactMap { rating -> ScoredPracticeAreaEntry? in
            guard
                rating.didPractice,
                let score = rating.score,
                let session = sessionByID[rating.sessionID]
            else { return nil }

            return ScoredPracticeAreaEntry(
                areaID: rating.practiceAreaID,
                areaName: rating.areaName,
                normalizedAreaName: normalizeAreaName(rating.areaName),
                sessionID: session.id,
                sessionType: session.sessionType,
                date: session.startTime,
                score: PracticeAreaRatingEntity.clampedScore(score),
                lastModified: rating.lastModified
            )
        })

        let activeAreas = practiceAreas
            .filter(\.isActive)
            .sorted { $0.order < $1.order }

        let activeAreasByMetricKey = Dictionary(
            activeAreas.map { (metricKey(for: $0.id), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let areasByMetricKey = Dictionary(
            practiceAreas.map { (metricKey(for: $0.id), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let groupedEntries = Dictionary(grouping: scoredEntries) { entry in
            metricKey(for: entry.areaID)
        }

        let areaKeys = Set(activeAreasByMetricKey.keys).union(groupedEntries.keys)

        return areaKeys
            .map { key in
                buildMetric(
                    metricKey: key,
                    area: areasByMetricKey[key],
                    entries: groupedEntries[key] ?? [],
                    now: now,
                    calendar: calendar
                )
            }
            .sorted { lhs, rhs in
                switch (lhs.isActive, rhs.isActive) {
                case (true, false):
                    return true
                case (false, true):
                    return false
                default:
                    return lhs.areaName.localizedCaseInsensitiveCompare(rhs.areaName) == .orderedAscending
                }
            }
    }
}

private extension PracticeAreaMetricsCalculator {

    struct ScoredPracticeAreaEntry {
        let areaID: UUID
        let areaName: String
        let normalizedAreaName: String
        let sessionID: UUID
        let sessionType: SessionType
        let date: Date
        let score: Int
        let lastModified: Date
    }

    static func deduplicatedEntries(
        _ entries: [ScoredPracticeAreaEntry]
    ) -> [ScoredPracticeAreaEntry] {
        let entriesByAreaAndSession = Dictionary(
            entries.map { entry in
                ("\(entry.areaID.uuidString)-\(entry.sessionID.uuidString)", entry)
            },
            uniquingKeysWith: { first, second in
                first.lastModified >= second.lastModified ? first : second
            }
        )

        return Array(entriesByAreaAndSession.values)
    }

    static func buildMetric(
        metricKey: String,
        area: PracticeAreaMetricAreaInput?,
        entries: [ScoredPracticeAreaEntry],
        now: Date,
        calendar: Calendar
    ) -> PracticeAreaMetric {

        let sortedEntries = entries.sorted { $0.date < $1.date }
        let latestEntry = sortedEntries.last

        let sevenDayAverage = average(
            entries: sortedEntries,
            from: daysBefore(7, now: now, calendar: calendar),
            to: now,
            includesEnd: true
        )

        let previousSevenDayAverage = average(
            entries: sortedEntries,
            from: daysBefore(14, now: now, calendar: calendar),
            to: daysBefore(7, now: now, calendar: calendar),
            includesEnd: false
        )

        let thirtyDayAverage = average(
            entries: sortedEntries,
            from: daysBefore(30, now: now, calendar: calendar),
            to: now,
            includesEnd: true
        )

        let daysSincePracticed = latestEntry.map {
            max(
                0,
                calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: $0.date),
                    to: calendar.startOfDay(for: now)
                ).day ?? 0
            )
        }

        let practiceEntries = sortedEntries.filter { $0.sessionType == .practice }
        let concertEntries = sortedEntries.filter { $0.sessionType == .concert }

        let areaName = area?.name ?? latestEntry?.areaName ?? metricKey

        return PracticeAreaMetric(
            id: metricKey,
            areaID: area?.id ?? latestEntry?.areaID,
            areaName: areaName,
            isActive: area?.isActive == true,
            latestScore: latestEntry?.score,
            sevenDayAverage: sevenDayAverage,
            previousSevenDayAverage: previousSevenDayAverage,
            thirtyDayAverage: thirtyDayAverage,
            trendDirection: trendDirection(
                sevenDayAverage: sevenDayAverage,
                previousSevenDayAverage: previousSevenDayAverage
            ),
            ratedSessionCount: sortedEntries.count,
            daysSincePracticed: daysSincePracticed,
            isNeglected: isNeglected(
                isActive: area?.isActive == true,
                daysSincePracticed: daysSincePracticed
            ),
            volatility: volatility(entries: sortedEntries),
            practice: contextMetric(entries: practiceEntries),
            concert: contextMetric(entries: concertEntries),
            scoreHistory: sortedEntries.map { entry in
                PracticeAreaScorePoint(
                    id: entry.sessionID,
                    date: entry.date,
                    score: entry.score,
                    sessionType: entry.sessionType
                )
            },
            performanceTransfer: performanceTransfer(
                practiceEntries: practiceEntries,
                concertEntries: concertEntries
            )
        )
    }

    static func average(
        entries: [ScoredPracticeAreaEntry],
        from start: Date,
        to end: Date,
        includesEnd: Bool
    ) -> Double? {
        let windowEntries = entries.filter { entry in
            entry.date >= start && (includesEnd ? entry.date <= end : entry.date < end)
        }

        return average(scores: windowEntries.map(\.score))
    }

    static func average(scores: [Int]) -> Double? {
        guard !scores.isEmpty else { return nil }

        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    static func contextMetric(
        entries: [ScoredPracticeAreaEntry]
    ) -> PracticeAreaContextMetric {
        PracticeAreaContextMetric(
            latestScore: entries.last?.score,
            averageScore: average(scores: entries.map(\.score)),
            ratedSessionCount: entries.count,
            volatility: volatility(entries: entries)
        )
    }

    static func trendDirection(
        sevenDayAverage: Double?,
        previousSevenDayAverage: Double?
    ) -> PracticeAreaTrendDirection {
        guard
            let sevenDayAverage,
            let previousSevenDayAverage
        else { return .insufficientData }

        let delta = sevenDayAverage - previousSevenDayAverage

        if delta >= 0.75 {
            return .improving
        } else if delta <= -0.75 {
            return .declining
        } else {
            return .stable
        }
    }

    static func isNeglected(
        isActive: Bool,
        daysSincePracticed: Int?
    ) -> Bool {
        guard isActive else { return false }

        guard let daysSincePracticed else { return true }

        return daysSincePracticed > neglectThresholdDays
    }

    static func volatility(
        entries: [ScoredPracticeAreaEntry]
    ) -> Double? {
        volatility(scores: entries.map(\.score))
    }

    static func volatility(scores: [Int]) -> Double? {
        guard scores.count >= 2 else { return nil }

        let mean = Double(scores.reduce(0, +)) / Double(scores.count)
        let variance = scores
            .map { pow(Double($0) - mean, 2) }
            .reduce(0, +) / Double(scores.count)

        return sqrt(variance)
    }

    static func performanceTransfer(
        practiceEntries: [ScoredPracticeAreaEntry],
        concertEntries: [ScoredPracticeAreaEntry]
    ) -> PracticeAreaPerformanceTransfer {
        guard
            practiceEntries.count >= minimumPracticeScoresForTransfer,
            concertEntries.count >= minimumConcertScoresForTransfer,
            let practiceAverage = average(scores: practiceEntries.map(\.score)),
            let concertAverage = average(scores: concertEntries.map(\.score))
        else {
            return PracticeAreaPerformanceTransfer(
                practiceAverage: average(scores: practiceEntries.map(\.score)),
                concertAverage: average(scores: concertEntries.map(\.score)),
                delta: nil,
                status: .insufficientData
            )
        }

        let delta = concertAverage - practiceAverage

        let status: PracticeAreaPerformanceTransferStatus
        if delta < significantDropDelta {
            status = .significantDrop
        } else if delta > concertLiftDelta {
            status = .concertLift
        } else if abs(delta) <= maintainedDeltaMagnitude {
            status = .maintained
        } else {
            status = .inconclusive
        }

        return PracticeAreaPerformanceTransfer(
            practiceAverage: practiceAverage,
            concertAverage: concertAverage,
            delta: delta,
            status: status
        )
    }

    static func daysBefore(
        _ days: Int,
        now: Date,
        calendar: Calendar
    ) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now) ?? now
    }

    static func metricKey(for areaID: UUID) -> String {
        "area:\(areaID.uuidString)"
    }

    static func normalizeAreaName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

enum PracticeRhythmCalculator {
    static func compute(
        sessions: [PracticeAreaMetricSessionInput],
        now: Date = Date(),
        calendar: Calendar = .current,
        dayCount: Int = 30
    ) -> PracticeRhythmMetric {
        let endDay = calendar.startOfDay(for: now)
        let startDay = calendar.date(
            byAdding: .day,
            value: -(dayCount - 1),
            to: endDay
        ) ?? endDay

        let practiceSessions = sessions.filter { session in
            session.sessionType == .practice
            && session.startTime >= startDay
            && session.startTime < calendar.date(byAdding: .day, value: 1, to: endDay) ?? now
        }

        let minutesByDay = Dictionary(
            grouping: practiceSessions,
            by: { calendar.startOfDay(for: $0.startTime) }
        )
        .mapValues { sessions in
            sessions.reduce(0) { total, session in
                let minutes = Int((session.duration / 60).rounded())
                return total + max(minutes, 1)
            }
        }

        let days = (0..<dayCount).compactMap { offset -> PracticeRhythmDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDay) else {
                return nil
            }

            return PracticeRhythmDay(
                id: date,
                date: date,
                practiceMinutes: minutesByDay[date, default: 0]
            )
        }

        let practicedDays = days.filter(\.didPractice).count
        let totalMinutes = days.map(\.practiceMinutes).reduce(0, +)

        return PracticeRhythmMetric(
            days: days,
            practicedDays: practicedDays,
            currentStreak: currentStreak(days: days),
            bestWeekPracticedDays: bestWeekPracticedDays(days: days),
            totalMinutes: totalMinutes
        )
    }
}

private extension PracticeRhythmCalculator {
    static func currentStreak(days: [PracticeRhythmDay]) -> Int {
        var streak = 0

        for day in days.reversed() {
            guard day.didPractice else { break }
            streak += 1
        }

        return streak
    }

    static func bestWeekPracticedDays(days: [PracticeRhythmDay]) -> Int {
        guard !days.isEmpty else { return 0 }

        return days.indices.map { index in
            let start = max(days.startIndex, index - 6)
            return days[start...index].filter(\.didPractice).count
        }
        .max() ?? 0
    }
}
