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

            HStack(spacing: 16) {
                PracticeAreaFocusDonutChart(
                    slices: displaySlices,
                    totalCount: totalCount,
                    countLabel: countLabel,
                    size: 116,
                    showsCenterLabel: true
                )

                VStack(spacing: 9) {
                    ForEach(displaySlices.prefix(4)) { slice in
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

    @State private var selectedWindow: PracticeMixWindow = .thirtyDays

    private var slices: [PracticeAreaFocusSlice] {
        PracticeAreaFocusSlice.slices(
            from: metrics,
            inLast: selectedWindow.dayCount
        )
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

                        Text("How much time relatively you spend on each of your active practice areas.")
                            .font(.subheadline)
                            .foregroundStyle(Color("SecondaryText"))
                    }

                    chartCard
                    mixSignalsCard
                }
                .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Practice mix window", selection: $selectedWindow) {
                ForEach(PracticeMixWindow.allCases) { window in
                    Text(window.label).tag(window)
                }
            }
            .pickerStyle(.segmented)

            if totalCount == 0 {
                Text("Reflect on practice sessions to build your mix for this window.")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
            } else {
                VStack(spacing: 16) {
                    PracticeAreaFocusDonutChart(
                        slices: displaySlices,
                        totalCount: totalCount,
                        countLabel: countLabel,
                        size: 286,
                        showsCenterLabel: true
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

    private var mixSignalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Focus Trends")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            if let topFocusSignal {
                PracticeAreaFocusSignalRow(
                    icon: "target",
                    title: "Top focus",
                    message: topFocusSignal,
                    tint: Color("AccentColor")
                )
            }

            if let underrepresentedSignal {
                PracticeAreaFocusSignalRow(
                    icon: "circle.dashed",
                    title: "Underrepresented",
                    message: underrepresentedSignal,
                    tint: .orange
                )
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    private var countLabel: String { "session" }

    private var topFocusSignal: String? {
        guard
            let topSlice = slices.first,
            totalCount > 0
        else { return nil }

        return "\(topSlice.name) makes up \(percentageText(for: topSlice)) of your reflected practice mix."
    }

    private var underrepresentedSignal: String? {
        let underrepresentedAreas = metrics
            .filter(\.isActive)
            .map { metric in
                PracticeAreaFocusSlice(
                    id: metric.id,
                    name: metric.areaName,
                    count: PracticeAreaFocusSlice.ratedPracticeCount(
                        for: metric,
                        inLast: selectedWindow.dayCount
                    )
                )
            }
            .filter { slice in
                slice.count == 0 || percentage(for: slice) < 10
            }
            .sorted {
                if $0.count == $1.count {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

                return $0.count < $1.count
            }

        guard !underrepresentedAreas.isEmpty else {
            return nil
        }

        let names = underrepresentedAreas
            .prefix(3)
            .map(\.name)
            .joined(separator: ", ")

        let remainingCount = underrepresentedAreas.count - min(underrepresentedAreas.count, 3)

        if remainingCount > 0 {
            return "\(names), and \(remainingCount) more are getting less than 10% of this window."
        }

        return "\(names) are getting less than 10% of this window."
    }

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

    private func percentage(for slice: PracticeAreaFocusSlice) -> Int {
        guard totalCount > 0 else { return 0 }
        return Int(round((Double(slice.count) / Double(totalCount)) * 100))
    }

    private func percentageText(for slice: PracticeAreaFocusSlice) -> String {
        PracticeAreaFocusPercentageFormatter.text(
            count: slice.count,
            totalCount: totalCount
        )
    }
}

private enum PracticeMixWindow: String, CaseIterable, Identifiable {
    case sevenDays
    case fourteenDays
    case thirtyDays
    case ninetyDays
    case oneYear

    var id: Self { self }

    var label: String {
        switch self {
        case .sevenDays:
            return "7D"
        case .fourteenDays:
            return "14D"
        case .thirtyDays:
            return "30D"
        case .ninetyDays:
            return "90D"
        case .oneYear:
            return "1Y"
        }
    }

    var dayCount: Int {
        switch self {
        case .sevenDays:
            return 7
        case .fourteenDays:
            return 14
        case .thirtyDays:
            return 30
        case .ninetyDays:
            return 90
        case .oneYear:
            return 365
        }
    }
}

private struct PracticeAreaFocusDonutChart: View {
    let slices: [PracticeAreaFocusSlice]
    let totalCount: Int
    let countLabel: String
    let size: CGFloat
    let showsCenterLabel: Bool

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
            if showsCenterLabel {
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
}

private struct PracticeAreaFocusSignalRow: View {
    let icon: String
    let title: String
    let message: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(tint.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("PrimaryText"))

                Text(message)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.08))
        )
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

            Text(percentageText)
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

    private var percentageText: String {
        PracticeAreaFocusPercentageFormatter.text(
            count: slice.count,
            totalCount: totalCount
        )
    }
}

enum PracticeAreaFocusPercentageFormatter {
    static func text(count: Int, totalCount: Int) -> String {
        guard totalCount > 0 else { return "0%" }

        let rawPercentage = (Double(count) / Double(totalCount)) * 100
        if count > 0 && rawPercentage < 1 {
            return "<1%"
        }

        return "\(Int(round(rawPercentage)))%"
    }
}

struct PracticeAreaFocusSlice: Identifiable {
    let id: String
    let name: String
    let count: Int
}

extension PracticeAreaFocusSlice {
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

    static func slices(
        from metrics: [PracticeAreaMetric],
        inLast dayCount: Int
    ) -> [PracticeAreaFocusSlice] {
        metrics
            .filter(\.isActive)
            .compactMap { metric -> PracticeAreaFocusSlice? in
                let count = ratedPracticeCount(for: metric, inLast: dayCount)
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

    static func ratedPracticeCount(
        for metric: PracticeAreaMetric,
        inLast dayCount: Int
    ) -> Int {
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -(dayCount - 1),
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date()

        return metric.scoreHistory.filter { point in
            point.sessionType == .practice && point.date >= cutoff
        }.count
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
