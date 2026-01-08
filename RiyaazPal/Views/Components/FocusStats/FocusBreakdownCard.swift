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
    let maxRows: Int = 3

    private var totalSessions: Int {
        focusStats.tagHistogram.values.reduce(0, +)
    }

    private var sortedTags: [(tag: String, count: Int)] {
        focusStats.tagHistogram
            .sorted { $0.value > $1.value }
            .prefix(maxRows)
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Breakdown")
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
