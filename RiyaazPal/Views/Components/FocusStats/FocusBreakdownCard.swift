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
    let maxLegendRows: Int = 3

    private var histogram: [String: Int] {
        focusStats.histogramsByCategory[category] ?? [:]
    }

    private var totalSessions: Int {
        histogram.values.reduce(0, +)
    }

 
    private var displayData: [(tag: String, count: Int)] {
        let sorted = histogram
            .sorted { $0.value > $1.value }
            .map { (tag: $0.key, count: $0.value) }

        guard sorted.count > maxLegendRows else {
            return sorted
        }

        let top = Array(sorted.prefix(maxLegendRows))
        let remaining = sorted.dropFirst(maxLegendRows)
        let otherCount = remaining.reduce(0) { $0 + $1.count }

        return top + [(tag: "Other", count: otherCount)]
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
                        .frame(width: 160, height: 200)

                    legendView
                }
            }
        }
    }
}


private extension FocusBreakdownCard {

    var chartView: some View {
        Chart(displayData, id: \.tag) { entry in
            SectorMark(
                angle: .value("Count", entry.count),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(color(for: entry.tag))
        }
        .chartLegend(.hidden)
    }
}

private extension FocusBreakdownCard {

    var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(displayData, id: \.tag) { entry in
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
}

private extension FocusBreakdownCard {

    var title: String {
        switch category.name {
        case "Section": return "Section Focus"
        case "Technique": return "Technique Focus"
        default: return "Focus Breakdown"
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

    func color(for tag: String) -> Color {
        if tag == "Other" {
            return Color.gray.opacity(0.4)
        }

        let palette: [Color] = [
            .red,
            .blue,
            .green,
            .orange,
            .purple,
            .pink,
            .teal,
            .indigo
        ]

        guard let index = displayData.firstIndex(where: { $0.tag == tag }) else {
            return palette[0]
        }

        return palette[index % palette.count]
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

#Preview("Focus Breakdown – Section (Other Visible)") {
    let section = TagCategory(
        id: UUID(),
        name: "Section",
        isFocusRelevant: true
    )

    let focusStats = FocusStats(
        histogramsByCategory: [
            section: [
                "alap": 7,
                "taan": 4,
                "jor": 3,
                "jhala": 2,
                "vilambit": 2,
                "drut": 1,
                "sargam": 1,
                "bol": 1
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
