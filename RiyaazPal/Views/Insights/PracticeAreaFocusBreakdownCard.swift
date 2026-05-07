//
//  PracticeAreaFocusBreakdownCard.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-07.
//

import Charts
import SwiftUI

struct PracticeAreaFocusBreakdownCard: View {
    let title: String
    let metrics: [PracticeAreaMetric]

    private var slices: [PracticeAreaFocusSlice] {
        metrics
            .compactMap { metric -> PracticeAreaFocusSlice? in
                let count = metric.practice.ratedSessionCount
                guard count > 0 else { return nil }
                return PracticeAreaFocusSlice(
                    id: metric.id,
                    name: metric.areaName,
                    count: count,
                    isActive: metric.isActive
                )
            }
            .sorted {
                if $0.count == $1.count {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

                return $0.count > $1.count
            }
    }

    private var displaySlices: [PracticeAreaFocusSlice] {
        guard slices.count > 5 else { return slices }

        let topSlices = Array(slices.prefix(4))
        let otherCount = slices.dropFirst(4).reduce(0) { $0 + $1.count }

        return topSlices + [
            PracticeAreaFocusSlice(
                id: "other",
                name: "Other",
                count: otherCount,
                isActive: true
            )
        ]
    }

    private var totalCount: Int {
        slices.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryText"))

                Spacer()

                Text(totalText)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            HStack(spacing: 16) {
                Chart(displaySlices) { slice in
                    SectorMark(
                        angle: .value("Count", slice.count),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .foregroundStyle(color(for: slice))
                }
                .chartLegend(.hidden)
                .frame(width: 116, height: 116)
                .overlay {
                    VStack(spacing: 1) {
                        Text("\(totalCount)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("PrimaryText"))

                        Text(countLabel)
                            .font(.caption2)
                            .foregroundStyle(Color("SecondaryText"))
                    }
                }

                VStack(spacing: 9) {
                    ForEach(displaySlices.prefix(4)) { slice in
                        legendRow(slice)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.08), radius: 10)
    }

    private var totalText: String {
        let noun = totalCount == 1 ? countLabel : "\(countLabel)s"
        return "\(totalCount) \(noun)"
    }

    private var countLabel: String { "session" }

    private func legendRow(_ slice: PracticeAreaFocusSlice) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color(for: slice))
                .frame(width: 9, height: 9)

            Text(slice.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color("PrimaryText"))
                .lineLimit(1)

            if !slice.isActive {
                Text("Archived")
                    .font(.caption2)
                    .foregroundStyle(Color("SecondaryText"))
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text("\(percentage(for: slice))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color("SecondaryText"))
        }
    }

    private func percentage(for slice: PracticeAreaFocusSlice) -> Int {
        guard totalCount > 0 else { return 0 }
        return Int(round((Double(slice.count) / Double(totalCount)) * 100))
    }

    private func color(for slice: PracticeAreaFocusSlice) -> Color {
        guard let index = displaySlices.firstIndex(where: { $0.id == slice.id }) else {
            return Color("AccentColor")
        }

        let palette: [Color] = [
            Color("AccentColor"),
            .teal,
            .orange,
            .indigo,
            .pink
        ]

        return palette[index % palette.count]
    }
}

private struct PracticeAreaFocusSlice: Identifiable {
    let id: String
    let name: String
    let count: Int
    let isActive: Bool
}

private extension View {
    func insightCard(background: Color = Color("CardBackground")) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(background)
            )
    }
}
