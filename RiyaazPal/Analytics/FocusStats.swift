//
//  FocusStats.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-07.
//

import Foundation

struct FocusStats {
    let histogramsByCategory: [TagCategory: [String: Int]]
}

extension FocusStats {
    func histogram(forCategoryNamed name: String) -> [String: Int]? {
        histogramsByCategory.first {
            $0.key.name.lowercased() == name.lowercased()
        }?.value
    }
}

enum FocusStatsCalculator {

    static func compute(
            sessions: [PracticeSession],
            categorizer: TagCategorizer
        ) -> FocusStats {

            var histograms: [TagCategory: [String: Int]] = [:]

            for session in sessions {
                let uniqueTags = Set(
                    session.tags.map(normalize)
                )

                for tag in uniqueTags {
                    let category = categorizer.category(for: tag)

                    guard isFocusRelevant(category) else { continue }

                    histograms[category, default: [:]][tag, default: 0] += 1
                }
            }

            return FocusStats(
                histogramsByCategory: histograms
            )
        }
}
 
private extension FocusStatsCalculator {
    static func normalize(_ tag: String) -> String {
        tag
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

private extension FocusStatsCalculator {

    static func isFocusRelevant(_ category: TagCategory) -> Bool {
        return category.isFocusRelevant
    }
}
