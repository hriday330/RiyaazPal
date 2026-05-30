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
        PracticeAreaFocusSlice.slices(from: metrics)
    }

    private var displaySlices: [PracticeAreaFocusSlice] {
        PracticeAreaFocusSlice.compactDisplaySlices(from: slices)
    }

    private var totalCount: Int {
        slices.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryText"))

                    Text("Active practice areas by rated sessions.")
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            HStack(spacing: 14) {
                PracticeAreaFocusDonutChart(
                    slices: displaySlices,
                    totalCount: totalCount,
                    countLabel: countLabel,
                    size: 82
                )

                VStack(spacing: 8) {
                    ForEach(displaySlices.prefix(3)) { slice in
                        legendRow(slice)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    private var countLabel: String { "session" }

    private func legendRow(_ slice: PracticeAreaFocusSlice) -> some View {
        PracticeAreaFocusLegendRow(
            slice: slice,
            totalCount: totalCount,
            color: PracticeAreaFocusPalette.color(
                for: slice,
                in: displaySlices
            ),
            showsCount: false
        )
    }
}

struct PracticeAreaFocusBreakdownDetailView: View {
    let title: String
    let metrics: [PracticeAreaMetric]

    private var slices: [PracticeAreaFocusSlice] {
        PracticeAreaFocusSlice.slices(from: metrics)
    }

    private var displaySlices: [PracticeAreaFocusSlice] {
        PracticeAreaFocusSlice.compactDisplaySlices(from: slices)
    }

    private var totalCount: Int {
        slices.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("PrimaryText"))

                        Text("How your active practice areas are represented across rated practice sessions.")
                            .font(.subheadline)
                            .foregroundStyle(Color("SecondaryText"))
                    }

                    chartCard
                    areaListCard
                }
                .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(totalCount)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AccentColor"))

                Text(totalCount == 1 ? "rated session" : "rated sessions")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            if totalCount == 0 {
                Text("Reflect on practice sessions to build your mix.")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
            } else {
                HStack(spacing: 18) {
                    PracticeAreaFocusDonutChart(
                        slices: displaySlices,
                        totalCount: totalCount,
                        countLabel: countLabel,
                        size: 144
                    )

                    VStack(spacing: 10) {
                        ForEach(displaySlices.prefix(5)) { slice in
                            legendRow(slice)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    private var areaListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Active Areas")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            if slices.isEmpty {
                Text("No active practice areas have ratings yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
            } else {
                ForEach(slices) { slice in
                    PracticeAreaFocusLegendRow(
                        slice: slice,
                        totalCount: totalCount,
                        color: PracticeAreaFocusPalette.color(
                            for: slice,
                            in: displaySlices
                        ),
                        showsCount: true
                    )
                }
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    private var countLabel: String { "session" }

    private func legendRow(_ slice: PracticeAreaFocusSlice) -> some View {
        PracticeAreaFocusLegendRow(
            slice: slice,
            totalCount: totalCount,
            color: PracticeAreaFocusPalette.color(
                for: slice,
                in: displaySlices
            ),
            showsCount: false
        )
    }
}

private struct PracticeAreaFocusDonutChart: View {
    let slices: [PracticeAreaFocusSlice]
    let totalCount: Int
    let countLabel: String
    let size: CGFloat

    var body: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Count", slice.count),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .foregroundStyle(PracticeAreaFocusPalette.color(for: slice, in: slices))
        }
        .chartLegend(.hidden)
        .frame(width: size, height: size)
        .overlay {
            VStack(spacing: 1) {
                Text("\(totalCount)")
                    .font(size > 100 ? .title2 : .title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("PrimaryText"))

                Text(totalCount == 1 ? countLabel : "\(countLabel)s")
                    .font(.caption2)
                    .foregroundStyle(Color("SecondaryText"))
            }
        }
    }
}

private struct PracticeAreaFocusLegendRow: View {
    let slice: PracticeAreaFocusSlice
    let totalCount: Int
    let color: Color
    let showsCount: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)

            Text(slice.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color("PrimaryText"))
                .lineLimit(1)

            Spacer(minLength: 6)

            if showsCount {
                Text(countText)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
                    .lineLimit(1)
            }

            Text("\(percentage)%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color("SecondaryText"))
        }
    }

    private var countText: String {
        let noun = slice.count == 1 ? "session" : "sessions"
        return "\(slice.count) \(noun)"
    }

    private var percentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int(round((Double(slice.count) / Double(totalCount)) * 100))
    }
}

private struct PracticeAreaFocusSlice: Identifiable {
    let id: String
    let name: String
    let count: Int
}

private extension PracticeAreaFocusSlice {
    static func slices(from metrics: [PracticeAreaMetric]) -> [PracticeAreaFocusSlice] {
        metrics
            .filter(\.isActive)
            .compactMap { metric -> PracticeAreaFocusSlice? in
                let count = metric.practice.ratedSessionCount
                guard count > 0 else { return nil }
                return PracticeAreaFocusSlice(
                    id: metric.id,
                    name: metric.areaName,
                    count: count
                )
            }
            .sorted {
                if $0.count == $1.count {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

                return $0.count > $1.count
            }
    }

    static func compactDisplaySlices(from slices: [PracticeAreaFocusSlice]) -> [PracticeAreaFocusSlice] {
        guard slices.count > 5 else { return slices }

        let topSlices = Array(slices.prefix(4))
        let otherCount = slices.dropFirst(4).reduce(0) { $0 + $1.count }

        return topSlices + [
            PracticeAreaFocusSlice(
                id: "other",
                name: "Other",
                count: otherCount
            )
        ]
    }
}

private enum PracticeAreaFocusPalette {
    static func color(
        for slice: PracticeAreaFocusSlice,
        in slices: [PracticeAreaFocusSlice]
    ) -> Color {
        guard let index = slices.firstIndex(where: { $0.id == slice.id }) else {
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

private extension View {
    func insightCard(background: Color = Color("InsightCardBackground")) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(background)
            )
    }
}
