//
//  PracticeScoreCalculator.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-09.
//

import Foundation

enum PracticeScoreCalculator {

    static func compute(
        consistency: ConsistencyStats,
        patterns: [PracticePattern]
    ) -> Int {

        let consistencyScore = consistencyComponent(consistency)
        let balanceScore = focusBalanceComponent(patterns)
        let sustainabilityScore = sustainabilityComponent(patterns)
        let stabilityScore = stabilityComponent(patterns)

        let total =
            consistencyScore +
            balanceScore +
            sustainabilityScore +
            stabilityScore

        return max(0, min(100, total))
    }
}

private extension PracticeScoreCalculator {

    static func consistencyComponent(
        _ stats: ConsistencyStats
    ) -> Int {

        guard stats.totalDays > 0 else { return 0 }

        let ratio =
            Double(stats.practicedDays) /
            Double(stats.totalDays)

        return Int(ratio * 40)
    }
}

private extension PracticeScoreCalculator {

    static func focusBalanceComponent(
        _ patterns: [PracticePattern]
    ) -> Int {

        let hasImbalance =
            patterns.contains { $0.id == "focus-imbalance" }

        return hasImbalance ? 15 : 25
    }
}

private extension PracticeScoreCalculator {

    static func sustainabilityComponent(
        _ patterns: [PracticePattern]
    ) -> Int {

        let hasFatigue =
            patterns.contains { $0.id == "fatigue-signal" }

        return hasFatigue ? 10 : 20
    }
}

private extension PracticeScoreCalculator {

    static func stabilityComponent(
        _ patterns: [PracticePattern]
    ) -> Int {

        let hasVolatility =
            patterns.contains { $0.id == "focus-volatility" }

        return hasVolatility ? 8 : 15
    }
}
