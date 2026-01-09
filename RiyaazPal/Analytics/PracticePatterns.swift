//
//  PracticePatterns.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-08.
//

import Foundation

struct PracticePattern: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
}


private enum PatternPriority: Int {
    case missingSection = 0
    case focusImbalance = 1
    case fatigueSignal = 2
    case focusVolatility = 3
}

enum PracticePatternCalculator {
    
    static func compute(
        sessions: [PracticeSession],
        focusStats: FocusStats
    ) -> [PracticePattern] {
        
        guard sessions.count >= 2 else { return [] }
        
        var patterns: [(PatternPriority, PracticePattern)] = []
        
        if let p = missingSections(from: focusStats) {
            patterns.append((.missingSection, p))
        }
        
        if let p = focusImbalance(
            from: focusStats,
            totalSessions: sessions.count
        ) {
            patterns.append((.focusImbalance, p))
        }
        
        if let p = fatigueSignal(from: sessions) {
            patterns.append((.fatigueSignal, p))
        }
        
        if let p = focusVolatility(from: sessions) {
            patterns.append((.focusVolatility, p))
        }
        
        return patterns
            .sorted { $0.0.rawValue < $1.0.rawValue }
            .prefix(2)
            .map { $0.1 }
    }
}

// MARK: - Focus Imbalance

private extension PracticePatternCalculator {

    static func focusImbalance(
        from stats: FocusStats,
        totalSessions: Int
    ) -> PracticePattern? {

        guard
            let sectionHistogram = stats.histogramsByCategory[.section],
            !sectionHistogram.isEmpty
        else { return nil }

        // Appears in very few sessions relative to window size
        let threshold = max(1, totalSessions / 6)

        guard
            let weakest = sectionHistogram.min(by: { $0.value < $1.value }),
            weakest.value <= threshold
        else { return nil }

        return PracticePattern(
            id: "focus-imbalance",
            icon: "music.note",
            title: "Focus Imbalance",
            description: "\(weakest.key.capitalized) appeared in only \(weakest.value) session\(weakest.value == 1 ? "" : "s")."
        )
    }
}

// MARK: - Missing Sections

private extension PracticePatternCalculator {

    static func missingSections(
        from stats: FocusStats
    ) -> PracticePattern? {

        let foundationalSections = ["gat", "alap"]

        let seenSections = Set(
            (stats.histogramsByCategory[.section] ?? [:]).keys
        )

        guard let missing = foundationalSections.first(where: {
            !seenSections.contains($0)
        }) else { return nil }

        return PracticePattern(
            id: "missing-section-\(missing)",
            icon: "exclamationmark.triangle",
            title: "Missing Practice Area",
            description: "\(missing.capitalized) did not appear in your recent practice."
        )
    }
}

// MARK: - Fatigue Signal

private extension PracticePatternCalculator {

    static func fatigueSignal(
        from sessions: [PracticeSession]
    ) -> PracticePattern? {

        let sorted = sessions.sorted { $0.startTime < $1.startTime }

        let longSession: TimeInterval = 60 * 60   // 60 min
        let shortSession: TimeInterval = 25 * 60  // 25 min

        for i in 0..<(sorted.count - 1) {
            let current = sorted[i]
            let next = sorted[i + 1]

            let gap = next.startTime.timeIntervalSince(current.startTime)

            if current.duration > longSession &&
               next.duration < shortSession &&
               gap < 24 * 60 * 60 {

                return PracticePattern(
                    id: "fatigue-signal",
                    icon: "clock",
                    title: "Fatigue Signal",
                    description: "Long sessions were often followed by shorter practice."
                )
            }
        }

        return nil
    }
}

// MARK: - Focus Volatility

private extension PracticePatternCalculator {

    static func focusVolatility(
        from sessions: [PracticeSession]
    ) -> PracticePattern? {

        guard sessions.count >= 3 else { return nil }

        let sorted = sessions.sorted { $0.startTime < $1.startTime }

        func normalizedFocusSet(_ session: PracticeSession) -> Set<String> {
            Set(
                session.tags
                    .map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased()
                    }
                    .filter {
                        let category = TagRegistry.category(for: $0)
                        return category == .section || category == .technique
                    }
            )
        }

        let focusSets = sorted.map(normalizedFocusSet)

        var largeJumps = 0

        for i in 0..<(focusSets.count - 1) {
            let a = focusSets[i]
            let b = focusSets[i + 1]

            let intersection = a.intersection(b).count
            let union = a.union(b).count

            guard union > 0 else { continue }

            let similarity = Double(intersection) / Double(union)

            // Low overlap → significant focus shift
            if similarity < 0.3 {
                largeJumps += 1
            }
        }

        guard largeJumps >= 2 else { return nil }

        return PracticePattern(
            id: "focus-volatility",
            icon: "waveform.path.ecg",
            title: "Shifting Focus",
            description: "Your focus areas changed significantly between sessions."
        )
    }
}
