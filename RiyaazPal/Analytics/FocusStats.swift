//
//  FocusStats.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-07.
//

import Foundation

struct FocusStats {
    let tagHistogram: [String: Int]
    let dominantTags: [String]
    let neglectedTags: [String]
}

enum FocusStatsCalculator {

    static func compute(
        sessions: [PracticeSession],
        dominantCount: Int = 3,
        neglectThreshold: Int = 0
    ) -> FocusStats {

        let allTagsInWindow: Set<String> = Set(
            sessions.flatMap { $0.tags.map(normalize) }
        )

        var histogram: [String: Int] = [:]

        for session in sessions {
            let uniqueTags = Set(session.tags.map(normalize))
            for tag in uniqueTags {
                histogram[tag, default: 0] += 1
            }
        }

        let sortedByFrequency = histogram
            .sorted { $0.value > $1.value }
        
        let dominantTags = sortedByFrequency
            .prefix(dominantCount)
            .map { $0.key }

        let neglectedTags = allTagsInWindow.filter { tag in
            histogram[tag, default: 0] <= neglectThreshold
        }

        return FocusStats(
            tagHistogram: histogram,
            dominantTags: dominantTags,
            neglectedTags: neglectedTags.sorted()
        )
    }
}

// MARK: - Tag Normalization

private extension FocusStatsCalculator {
    static func normalize(_ tag: String) -> String {
        tag
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

