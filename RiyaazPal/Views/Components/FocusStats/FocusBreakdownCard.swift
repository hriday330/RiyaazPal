//
//  FocusBreakdownCard.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-07.
//

import Foundation
import SwiftUI

struct FocusBreakdownCard: View {

    let focusStats: FocusStats
    let category: TagCategory
    let maxRows: Int = 3

    private var histogram: [String: Int] {
        focusStats.histogramsByCategory[category] ?? [:]
    }

    private var totalSessions: Int {
        histogram.values.reduce(0, +)
    }

    private var sortedTags: [(tag: String, count: Int)] {
        histogram
            .sorted { $0.value > $1.value }
            .prefix(maxRows)
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if totalSessions == 0 {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(sortedTags, id: \.tag) { entry in
                        focusRow(
                            label: entry.tag,
                            percent: percentage(for: entry.count)
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
}

private extension FocusBreakdownCard {

    var title: String {
            switch category {
            case .section:
                return "Section Focus"
            case .technique:
                return "Technique Focus"
            default:
                return "Focus Breakdown"
            }
        }
    
    func percentage(for count: Int) -> Int {
        guard totalSessions > 0 else { return 0 }
        return Int(round((Double(count) / Double(totalSessions)) * 100))
    }
    var emptyState: some View {
        Text("Not enough data to determine focus yet.")
            .font(.subheadline)
            .foregroundStyle(Color("SecondaryText"))
    }

    func focusRow(label: String, percent: Int) -> some View {
        HStack {
            Text(label.capitalized)
                .font(.subheadline)
                .foregroundStyle(Color("PrimaryText"))

            Spacer()

            Text("\(percent)%")
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
        }
    }
}

#Preview("Focus Breakdown – Section") {
    let focusStats = FocusStats(
        histogramsByCategory: [
            .section: [
                "alap": 4,
                "taan": 2,
                "jor": 1
            ],
            .technique: [
                "meend": 3,
                "kan": 2
            ]
        ]
    )

    return FocusBreakdownCard(
        focusStats: focusStats,
        category: .section
    )
    .padding()
    .background(Color("AppBackground"))
    .preferredColorScheme(.light)
}

#Preview("Focus Breakdown – Technique") {
    let focusStats = FocusStats(
        histogramsByCategory: [
            .section: [
                "alap": 3,
                "taan": 1
            ],
            .technique: [
                "meend": 3,
                "kan": 3,
                "gamak": 1
            ]
        ]
    )

    return FocusBreakdownCard(
        focusStats: focusStats,
        category: .technique
    )
    .padding(10)
    .background(Color("AppBackground"))
    .preferredColorScheme(.light)
}
