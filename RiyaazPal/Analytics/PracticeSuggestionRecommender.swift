//
//  PracticeSuggestionRecommender.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-05.
//

import Foundation

struct PracticeSuggestionRecommendation: Equatable {
    let areaID: UUID?
    let areaName: String
    let priorityScore: Double
    let primaryReason: PracticeSuggestionReason
    let supportingReasons: [PracticeSuggestionReason]
}

enum PracticeSuggestionReason: Equatable {
    case noRatingsYet
    case neglected(days: Int?)
    case dueForPractice(days: Int)
    case concertDrop(delta: Double?)
    case decliningTrend
    case lowerRecentScore(score: Int)
    case highVolatility(volatility: Double)
    case steadyMaintenance
}

enum PracticeSuggestionRecommender {

    static func recommend(
        from metrics: [PracticeAreaMetric]
    ) -> PracticeSuggestionRecommendation? {
        rankedRecommendations(from: metrics).first
    }

    static func rankedRecommendations(
        from metrics: [PracticeAreaMetric]
    ) -> [PracticeSuggestionRecommendation] {
        metrics
            .filter(\.isActive)
            .map(candidate)
            .sorted { lhs, rhs in
                if lhs.priorityScore == rhs.priorityScore {
                    return lhs.areaName.localizedCaseInsensitiveCompare(rhs.areaName) == .orderedAscending
                }

                return lhs.priorityScore > rhs.priorityScore
            }
    }
}

private extension PracticeSuggestionRecommender {

    struct ScoredReason {
        let reason: PracticeSuggestionReason
        let score: Double
    }

    static func candidate(
        for metric: PracticeAreaMetric
    ) -> PracticeSuggestionRecommendation {
        let scoredReasons = scoredReasons(for: metric)
        let totalScore = scoredReasons.reduce(0) { $0 + $1.score }
        let orderedReasons = scoredReasons
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.reason.sortRank < rhs.reason.sortRank
                }

                return lhs.score > rhs.score
            }
            .map(\.reason)

        return PracticeSuggestionRecommendation(
            areaID: metric.areaID,
            areaName: metric.areaName,
            priorityScore: totalScore,
            primaryReason: orderedReasons.first ?? .steadyMaintenance,
            supportingReasons: Array(orderedReasons.dropFirst())
        )
    }

    static func scoredReasons(
        for metric: PracticeAreaMetric
    ) -> [ScoredReason] {
        var reasons: [ScoredReason] = []

        if metric.ratedSessionCount == 0 {
            reasons.append(ScoredReason(reason: .noRatingsYet, score: 7))
        }

        if metric.isNeglected {
            reasons.append(
                ScoredReason(
                    reason: .neglected(days: metric.daysSincePracticed),
                    score: 6
                )
            )
        }

        if metric.performanceTransfer.status == .significantDrop {
            reasons.append(
                ScoredReason(
                    reason: .concertDrop(delta: metric.performanceTransfer.delta),
                    score: 5
                )
            )
        }

        if metric.trendDirection == .declining {
            reasons.append(ScoredReason(reason: .decliningTrend, score: 4))
        }

        if let latestScore = metric.latestScore, latestScore <= 6 {
            reasons.append(
                ScoredReason(
                    reason: .lowerRecentScore(score: latestScore),
                    score: Double(7 - latestScore)
                )
            )
        }

        if let daysSincePracticed = metric.daysSincePracticed, daysSincePracticed > 0 {
            let recencyScore = min(Double(daysSincePracticed) / 3, 3)
            reasons.append(ScoredReason(reason: .dueForPractice(days: daysSincePracticed), score: recencyScore))
        }

        if let volatility = metric.volatility, volatility >= 1.5 {
            reasons.append(
                ScoredReason(
                    reason: .highVolatility(volatility: volatility),
                    score: min(volatility, 3)
                )
            )
        }

        if reasons.isEmpty {
            reasons.append(ScoredReason(reason: .steadyMaintenance, score: 1))
        }

        return coalescedReasons(reasons)
    }

    static func coalescedReasons(
        _ reasons: [ScoredReason]
    ) -> [ScoredReason] {
        var result: [ScoredReason] = []

        for entry in reasons {
            if let index = result.firstIndex(
                where: { $0.reason.coalescingKey == entry.reason.coalescingKey }
            ) {
                result[index] = ScoredReason(
                    reason: result[index].reason,
                    score: max(result[index].score, entry.score)
                )
            } else {
                result.append(entry)
            }
        }

        return result
    }
}

private extension PracticeSuggestionReason {
    var coalescingKey: String {
        switch self {
        case .noRatingsYet:
            return "noRatingsYet"
        case .neglected:
            return "neglected"
        case .dueForPractice:
            return "dueForPractice"
        case .concertDrop:
            return "concertDrop"
        case .decliningTrend:
            return "decliningTrend"
        case .lowerRecentScore:
            return "lowerRecentScore"
        case .highVolatility:
            return "highVolatility"
        case .steadyMaintenance:
            return "steadyMaintenance"
        }
    }

    var sortRank: Int {
        switch self {
        case .noRatingsYet:
            return 0
        case .neglected:
            return 1
        case .dueForPractice:
            return 2
        case .concertDrop:
            return 3
        case .decliningTrend:
            return 4
        case .lowerRecentScore:
            return 5
        case .highVolatility:
            return 6
        case .steadyMaintenance:
            return 7
        }
    }
}
