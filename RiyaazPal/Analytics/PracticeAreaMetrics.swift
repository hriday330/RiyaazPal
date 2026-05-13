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
                sessionType: session.resolvedSessionType,
                date: session.startTime,
                score: PracticeAreaRatingEntity.clampedScore(score),
                lastModified: rating.lastModified
            )
        })

        let activeAreasByName = Dictionary(
            practiceAreas
                .filter(\.isActive)
                .sorted { $0.order < $1.order }
                .map { (normalizeAreaName($0.name), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let groupedEntries = Dictionary(grouping: scoredEntries) { entry in
            entry.normalizedAreaName
        }

        let areaKeys = Set(activeAreasByName.keys).union(groupedEntries.keys)

        return areaKeys
            .map { key in
                buildMetric(
                    normalizedAreaName: key,
                    activeArea: activeAreasByName[key],
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
                ("\(entry.normalizedAreaName)-\(entry.sessionID.uuidString)", entry)
            },
            uniquingKeysWith: { first, second in
                first.lastModified >= second.lastModified ? first : second
            }
        )

        return Array(entriesByAreaAndSession.values)
    }

    static func buildMetric(
        normalizedAreaName: String,
        activeArea: PracticeAreaEntity?,
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

        let areaName = activeArea?.name ?? latestEntry?.areaName ?? normalizedAreaName

        return PracticeAreaMetric(
            id: normalizedAreaName,
            areaID: activeArea?.id ?? latestEntry?.areaID,
            areaName: areaName,
            isActive: activeArea != nil,
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
                isActive: activeArea != nil,
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

    static func normalizeAreaName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
