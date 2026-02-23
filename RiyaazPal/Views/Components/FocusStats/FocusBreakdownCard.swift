//
//  FocusBreakdownCard.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-07.
//

import Foundation
import SwiftUI
import Charts

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
                HStack(spacing: 20) {
                    chartView
                        .frame(width: 160, height: 240)
                    legendView
                }
            }
        }
    }
}

private extension FocusBreakdownCard {

    var chartView: some View {
        Chart(sortedTags, id: \.tag) { entry in
            SectorMark(
                angle: .value("Count", entry.count),
                innerRadius: .ratio(0.6),   // makes it donut style
                angularInset: 2
            )
            .foregroundStyle(by: .value("Tag", entry.tag))
        }
        .chartLegend(.hidden)
    }
}

private extension FocusBreakdownCard {

    var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sortedTags, id: \.tag) { entry in
                HStack(spacing: 8) {

                    Circle()
                        .fill(color(for: entry.tag))
                        .frame(width: 10, height: 10)

                    Text(entry.tag.capitalized)
                        .font(.subheadline)

                    Spacer()

                    Text("\(percentage(for: entry.count))%")
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                }
            }
        }
    }

    func color(for tag: String) -> Color {
        let index = sortedTags.firstIndex(where: { $0.tag == tag }) ?? 0
        let palette: [Color] = [
            Color("AccentColor"),
            .blue,
            .green,
            .orange,
            .purple
        ]
        return palette[index % palette.count]
    }
}
private extension FocusBreakdownCard {

    var title: String {
        switch category.name {
            case "Section":
                return "Section Focus"
            case "Technique":
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
        Text("Add tags to your sessions to view focus data")
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
    let section = TagCategory(
        id: UUID(),
        name: "Section",
        isFocusRelevant: true
    )

    let focusStats = FocusStats(
        histogramsByCategory: [
            section: [
                "alap": 4,
                "taan": 2,
                "jor": 1
            ]
        ]
    )

    return FocusBreakdownCard(
        focusStats: focusStats,
        category: section
    )
    .padding()
    .background(Color("AppBackground"))
    .preferredColorScheme(.light)
}
