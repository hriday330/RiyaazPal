//
//  PracticeAreaInsightsContent.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-04.
//

import SwiftUI

struct PracticeAreaInsightRoute: Hashable {
    let metricID: String
}

struct PracticeRhythmRoute: Hashable {}

struct PracticeAreaInsightsContent: View {
    let metrics: [PracticeAreaMetric]
    let rhythmMetric: PracticeRhythmMetric
    let activePracticeAreaCount: Int
    let onManagePracticeAreas: () -> Void

    private let activeMetrics: [PracticeAreaMetric]
    private let ratedMetrics: [PracticeAreaMetric]
    private let attentionMetrics: [PracticeAreaMetric]
    private let improvingMetrics: [PracticeAreaMetric]

    init(
        metrics: [PracticeAreaMetric],
        rhythmMetric: PracticeRhythmMetric,
        activePracticeAreaCount: Int,
        onManagePracticeAreas: @escaping () -> Void
    ) {
        self.metrics = metrics
        self.rhythmMetric = rhythmMetric
        self.activePracticeAreaCount = activePracticeAreaCount
        self.onManagePracticeAreas = onManagePracticeAreas

        let activeMetrics = metrics.filter(\.isActive)
        self.activeMetrics = activeMetrics
        self.ratedMetrics = metrics.filter { $0.practice.ratedSessionCount > 0 }
        self.attentionMetrics = activeMetrics
            .filter { metric in
                metric.isNeglected
                || metric.trendDirection == .declining
                || metric.performanceTransfer.status == .significantDrop
            }
            .sorted(by: Self.attentionSort)
        self.improvingMetrics = activeMetrics
            .filter { $0.trendDirection == .improving }
            .sorted { lhs, rhs in
                (lhs.sevenDayAverage ?? 0) > (rhs.sevenDayAverage ?? 0)
            }
    }

    var body: some View {
        LazyVStack(spacing: 16) {
            if activePracticeAreaCount == 0 {
                PracticeAreaInsightsEmptyState(
                    title: "No practice areas yet",
                    message: "Add practice areas from Profile to start seeing score trends.",
                    buttonTitle: "Add Practice Areas",
                    onButtonTapped: onManagePracticeAreas
                )
            } else if ratedMetrics.isEmpty {
                PracticeAreaInsightsEmptyState(
                    title: "No ratings yet",
                    message: "Reflect on sessions to build trends for each practice area.",
                    buttonTitle: "Manage Practice Areas",
                    onButtonTapped: onManagePracticeAreas
                )
            } else {
                PracticeAreaOverviewCard(metrics: activeMetrics)

                NavigationLink(value: PracticeRhythmRoute()) {
                    PracticeRhythmCard(metric: rhythmMetric)
                }
                .buttonStyle(.plain)

                PracticeAreaFocusBreakdownCard(
                    title: "Practice Mix",
                    metrics: metrics
                )

                if !attentionMetrics.isEmpty || !improvingMetrics.isEmpty {
                    PracticeAreaHighlightsCard(
                        attentionMetrics: Array(attentionMetrics.prefix(3)),
                        improvingMetrics: Array(improvingMetrics.prefix(3))
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Practice Areas")
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryText"))

                    ForEach(metrics) { metric in
                        NavigationLink(value: PracticeAreaInsightRoute(metricID: metric.id)) {
                            PracticeAreaMetricCard(metric: metric)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private static func attentionSort(
        lhs: PracticeAreaMetric,
        rhs: PracticeAreaMetric
    ) -> Bool {
        attentionScore(lhs) > attentionScore(rhs)
    }

    private static func attentionScore(_ metric: PracticeAreaMetric) -> Int {
        var score = 0
        if metric.isNeglected { score += 4 }
        if metric.performanceTransfer.status == .significantDrop { score += 3 }
        if metric.trendDirection == .declining { score += 2 }
        if metric.daysSincePracticed ?? 0 > 10 { score += 1 }
        return score
    }
}

private struct PracticeRhythmCard: View {
    let metric: PracticeRhythmMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice Rhythm")
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryText"))

                    Text("Practiced days over the last 30 days.")
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            PracticeRhythmHeatmap(
                days: metric.days,
                columnsCount: 7,
                spacing: 3,
                cornerRadius: 2,
                cellSize: 9
            )

            HStack(spacing: 12) {
                rhythmStat(value: "\(metric.currentStreak)", label: "Streak")
                rhythmStat(value: "\(metric.practicedDays)/30", label: "Practiced")
                rhythmStat(value: averageMinutesText, label: "Avg min")
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    private var averageMinutesText: String {
        guard let average = metric.averageMinutesPerPracticedDay else { return "-" }
        return "\(average)"
    }

    private func rhythmStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryText"))

            Text(label)
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PracticeRhythmDetailView: View {
    let metric: PracticeRhythmMetric
    @State private var selectedWindow: PracticeRhythmWindow = .thirtyDays

    private var selectedDays: [PracticeRhythmDay] {
        Array(metric.days.suffix(selectedWindow.dayCount))
    }

    private var selectedStats: PracticeRhythmWindowStats {
        PracticeRhythmWindowStats(days: selectedDays)
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Practice Rhythm")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("PrimaryText"))

                        Text("Your practiced days and total minutes over the selected window.")
                            .font(.subheadline)
                            .foregroundStyle(Color("SecondaryText"))
                    }

                    fullHeatmapCard
                    detailStatsCard
                }
                .padding()
            }
        }
        .navigationTitle("Practice Rhythm")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fullHeatmapCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Rhythm window", selection: $selectedWindow) {
                ForEach(PracticeRhythmWindow.allCases) { window in
                    Text(window.label).tag(window)
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .firstTextBaseline) {
                Text("\(selectedStats.practicedDays)/\(selectedWindow.dayCount)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AccentColor"))

                Text("days practiced")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            PracticeRhythmHeatmap(
                days: selectedDays,
                columnsCount: 7,
                spacing: 5,
                cornerRadius: 4,
                cellSize: nil
            )

            PracticeRhythmHeatmapLegend()
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    private var detailStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rhythm Details")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            HStack(spacing: 12) {
                detailStat(value: "\(selectedStats.currentStreak)", label: "Current streak")
                detailStat(value: "\(selectedStats.bestWeekPracticedDays)/7", label: "Best week")
            }

            HStack(spacing: 12) {
                detailStat(value: averageMinutesText, label: "Avg minutes")
                detailStat(value: "\(selectedStats.totalMinutes)", label: "Total minutes")
            }

            HStack(spacing: 12) {
                detailStat(value: weeklyRhythmText, label: "Weekly rhythm")
                detailStat(value: mostActiveDayText, label: "Most active day")
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    private var averageMinutesText: String {
        guard let average = selectedStats.averageMinutesPerPracticedDay else { return "-" }
        return "\(average)"
    }

    private var weeklyRhythmText: String {
        selectedStats.weeklyRhythm.formatted(.number.precision(.fractionLength(1)))
    }

    private var mostActiveDayText: String {
        guard let mostActiveDay = selectedStats.mostActiveDay else { return "-" }

        let weekday = mostActiveDay.date.formatted(.dateTime.weekday(.abbreviated))
        return "\(weekday), \(mostActiveDay.practiceMinutes)m"
    }

    private func detailStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryText"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum PracticeRhythmWindow: String, CaseIterable, Identifiable {
    case sevenDays
    case fourteenDays
    case thirtyDays

    var id: Self { self }

    var label: String {
        switch self {
        case .sevenDays:
            return "7D"
        case .fourteenDays:
            return "14D"
        case .thirtyDays:
            return "30D"
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
        }
    }
}

private struct PracticeRhythmWindowStats {
    let days: [PracticeRhythmDay]

    var practicedDays: Int {
        days.filter(\.didPractice).count
    }

    var currentStreak: Int {
        var streak = 0

        for day in days.reversed() {
            guard day.didPractice else { break }
            streak += 1
        }

        return streak
    }

    var bestWeekPracticedDays: Int {
        guard !days.isEmpty else { return 0 }

        return days.indices.map { index in
            let start = max(days.startIndex, index - 6)
            return days[start...index].filter(\.didPractice).count
        }
        .max() ?? 0
    }

    var totalMinutes: Int {
        days.map(\.practiceMinutes).reduce(0, +)
    }

    var averageMinutesPerPracticedDay: Int? {
        guard practicedDays > 0 else { return nil }
        return Int((Double(totalMinutes) / Double(practicedDays)).rounded())
    }

    var weeklyRhythm: Double {
        guard !days.isEmpty else { return 0 }
        return Double(practicedDays) / Double(days.count) * 7
    }

    var mostActiveDay: PracticeRhythmDay? {
        days
            .filter(\.didPractice)
            .max { lhs, rhs in
                lhs.practiceMinutes < rhs.practiceMinutes
            }
    }
}

private struct PracticeRhythmHeatmap: View {
    let days: [PracticeRhythmDay]
    let columnsCount: Int
    let spacing: CGFloat
    let cornerRadius: CGFloat
    let cellSize: CGFloat?

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: columnsCount
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(days) { day in
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(PracticeRhythmColorScale.color(for: day))
                    .frame(width: cellSize, height: cellSize)
                    .aspectRatio(1, contentMode: .fit)
                    .accessibilityLabel(accessibilityLabel(for: day))
            }
        }
    }

    private func accessibilityLabel(for day: PracticeRhythmDay) -> String {
        let date = day.date.formatted(date: .abbreviated, time: .omitted)

        if day.didPractice {
            return "\(date), \(day.practiceMinutes) practice minutes"
        }

        return "\(date), no practice"
    }
}

private struct PracticeRhythmHeatmapLegend: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(Color("SecondaryText"))

            ForEach(PracticeRhythmLegendBucket.allCases) { bucket in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(bucket.color)
                    .frame(width: 14, height: 14)
                    .accessibilityLabel(bucket.accessibilityLabel)
            }

            Text("More")
                .font(.caption2)
                .foregroundStyle(Color("SecondaryText"))

            Spacer()
        }
    }
}

private enum PracticeRhythmLegendBucket: CaseIterable, Identifiable {
    case none
    case short
    case medium
    case long
    case extended

    var id: Self { self }

    var color: Color {
        PracticeRhythmColorScale.color(for: self)
    }

    var accessibilityLabel: String {
        switch self {
        case .none:
            return "No practice"
        case .short:
            return "Less than 30 practice minutes"
        case .medium:
            return "30 to 59 practice minutes"
        case .long:
            return "60 to 89 practice minutes"
        case .extended:
            return "90 or more practice minutes"
        }
    }
}

private enum PracticeRhythmColorScale {
    static func color(for day: PracticeRhythmDay) -> Color {
        guard day.didPractice else {
            return color(for: PracticeRhythmLegendBucket.none)
        }

        switch day.practiceMinutes {
        case 0..<30:
            return color(for: .short)
        case 30..<60:
            return color(for: .medium)
        case 60..<90:
            return color(for: .long)
        default:
            return color(for: .extended)
        }
    }

    static func color(for bucket: PracticeRhythmLegendBucket) -> Color {
        switch bucket {
        case .none:
            return Color("SecondaryText").opacity(0.10)
        case .short:
            return Color.green.opacity(0.30)
        case .medium:
            return Color.green.opacity(0.48)
        case .long:
            return Color.green.opacity(0.66)
        case .extended:
            return Color.green.opacity(0.84)
        }
    }
}

private struct PracticeAreaOverviewCard: View {
    let metrics: [PracticeAreaMetric]

    private var latestAverage: Double? {
        let scores = metrics.compactMap(\.latestScore)
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    private var improvingCount: Int {
        metrics.filter { $0.trendDirection == .improving }.count
    }

    private var attentionCount: Int {
        metrics.filter {
            $0.isNeglected
            || $0.trendDirection == .declining
            || $0.performanceTransfer.status == .significantDrop
        }.count
    }

    private var ratedCount: Int {
        metrics.filter { $0.ratedSessionCount > 0 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice Area Health")
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryText"))

                    Text("Average of the latest scores for active practice areas.")
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }

                Spacer()

                Text(scoreText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AccentColor"))
            }

            HStack(spacing: 12) {
                overviewMetric(value: "\(ratedCount)", label: "Rated areas")
                overviewMetric(value: "\(improvingCount)", label: "Improving")
                overviewMetric(value: "\(attentionCount)", label: "Needs attention")
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    private var scoreText: String {
        guard let latestAverage else { return "-" }
        return "\(latestAverage.formatted(.number.precision(.fractionLength(1))))/10"
    }

    private func overviewMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryText"))

            Text(label)
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PracticeAreaHighlightsCard: View {
    let attentionMetrics: [PracticeAreaMetric]
    let improvingMetrics: [PracticeAreaMetric]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What To Watch")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            if !attentionMetrics.isEmpty {
                PracticeAreaHighlightGroup(
                    icon: "exclamationmark.triangle.fill",
                    title: "Needs attention",
                    metrics: attentionMetrics,
                    summary: attentionSummary
                )
            }

            if !improvingMetrics.isEmpty {
                PracticeAreaHighlightGroup(
                    icon: "arrow.up.right.circle.fill",
                    title: "Moving up",
                    metrics: improvingMetrics,
                    summary: improvingSummary
                )
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    private func attentionSummary(for metric: PracticeAreaMetric) -> String {
        if metric.isNeglected {
            return "Not practiced in \(metric.daysSincePracticed ?? 0) days."
        }

        if metric.performanceTransfer.status == .significantDrop {
            return "Concert execution is trailing practice."
        }

        return "Recent 7-day average is lower than the previous week."
    }

    private func improvingSummary(for metric: PracticeAreaMetric) -> String {
        guard let average = metric.sevenDayAverage else {
            return "Recent scores are improving."
        }

        return "Recent average is \(average.formatted(.number.precision(.fractionLength(1))))/10."
    }
}

private struct PracticeAreaHighlightGroup: View {
    let icon: String
    let title: String
    let metrics: [PracticeAreaMetric]
    let summary: (PracticeAreaMetric) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color("AccentColor"))

            ForEach(metrics) { metric in
                HStack(alignment: .top, spacing: 10) {
                    Text(metric.areaName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("PrimaryText"))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(summary(metric))
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

private struct PracticeAreaMetricCard: View {
    let metric: PracticeAreaMetric

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(metric.areaName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("PrimaryText"))

                    if !metric.isActive {
                        Text("Archived")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color("SecondaryText").opacity(0.14))
                            )
                            .foregroundStyle(Color("SecondaryText"))
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(latestScoreText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AccentColor"))

                PracticeAreaStatusChip(
                    icon: metric.trendDirection.iconName,
                    text: metric.trendDirection.label,
                    tint: metric.trendDirection.tint
                )
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    private var subtitle: String {
        let count = metric.ratedSessionCount
        let countText = count == 1 ? "1 rated session" : "\(count) rated sessions"

        guard let days = metric.daysSincePracticed else {
            return "\(countText) - not practiced yet"
        }

        if days == 0 {
            return "\(countText) - practiced today"
        }

        return "\(countText) - \(days) days since practiced"
    }

    private var latestScoreText: String {
        guard let latestScore = metric.latestScore else { return "-" }
        return "\(latestScore)/10"
    }

}

private struct PracticeAreaStatusChip: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .fontWeight(.semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(tint.opacity(0.14))
            )
            .foregroundStyle(tint)
    }
}

private struct PracticeAreaInsightsEmptyState: View {
    let title: String
    let message: String
    let buttonTitle: String
    let onButtonTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "slider.horizontal.3")
                .font(.title2)
                .foregroundStyle(Color("AccentColor"))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryText"))

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Button(action: onButtonTapped) {
                Label(buttonTitle, systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("AccentColor"))
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }
}

private extension PracticeAreaTrendDirection {
    var label: String {
        switch self {
        case .improving:
            return "Improving"
        case .declining:
            return "Declining"
        case .stable:
            return "Stable"
        case .insufficientData:
            return "Need more data"
        }
    }

    var iconName: String {
        switch self {
        case .improving:
            return "arrow.up.right"
        case .declining:
            return "arrow.down.right"
        case .stable:
            return "equal"
        case .insufficientData:
            return "chart.line.uptrend.xyaxis"
        }
    }

    var tint: Color {
        switch self {
        case .improving:
            return .green
        case .declining:
            return .red
        case .stable:
            return Color("AccentColor")
        case .insufficientData:
            return Color("SecondaryText")
        }
    }
}

private extension PracticeAreaPerformanceTransferStatus {
    var label: String {
        switch self {
        case .significantDrop:
            return "Concert drop detected"
        case .concertLift:
            return "Concert execution stronger"
        case .maintained:
            return "Concert execution maintained"
        case .inconclusive:
            return "Practice vs concert is inconclusive"
        case .insufficientData:
            return "Need more concert data"
        }
    }

    var iconName: String {
        switch self {
        case .significantDrop:
            return "exclamationmark.triangle.fill"
        case .concertLift:
            return "arrow.up.forward.circle.fill"
        case .maintained:
            return "checkmark.circle.fill"
        case .inconclusive:
            return "questionmark.circle.fill"
        case .insufficientData:
            return "chart.bar.xaxis"
        }
    }

    var tint: Color {
        switch self {
        case .significantDrop:
            return .red
        case .concertLift:
            return .green
        case .maintained:
            return .green
        case .inconclusive:
            return .orange
        case .insufficientData:
            return Color("SecondaryText")
        }
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

#Preview("Practice Area Insights") {
    let metrics = [
        PracticeAreaMetric(
            id: "alap",
            areaID: UUID(),
            areaName: "Alap",
            isActive: true,
            latestScore: 8,
            sevenDayAverage: 8.2,
            previousSevenDayAverage: 7.1,
            thirtyDayAverage: 7.6,
            trendDirection: .improving,
            ratedSessionCount: 12,
            daysSincePracticed: 1,
            isNeglected: false,
            volatility: 0.7,
            practice: PracticeAreaContextMetric(
                latestScore: 8,
                averageScore: 8.1,
                ratedSessionCount: 9,
                volatility: 0.7
            ),
            concert: PracticeAreaContextMetric(
                latestScore: 7,
                averageScore: 7.5,
                ratedSessionCount: 3,
                volatility: 0.6
            ),
            performanceTransfer: PracticeAreaPerformanceTransfer(
                practiceAverage: 8.1,
                concertAverage: 7.5,
                delta: -0.6,
                status: .maintained
            )
        ),
        PracticeAreaMetric(
            id: "layakari",
            areaID: UUID(),
            areaName: "Layakari",
            isActive: true,
            latestScore: 5,
            sevenDayAverage: 5.1,
            previousSevenDayAverage: 6.8,
            thirtyDayAverage: 6.0,
            trendDirection: .declining,
            ratedSessionCount: 8,
            daysSincePracticed: 7,
            isNeglected: true,
            volatility: 1.9,
            practice: PracticeAreaContextMetric(
                latestScore: 5,
                averageScore: 6.2,
                ratedSessionCount: 5,
                volatility: 1.4
            ),
            concert: PracticeAreaContextMetric(
                latestScore: 4,
                averageScore: 4.1,
                ratedSessionCount: 3,
                volatility: 1.1
            ),
            performanceTransfer: PracticeAreaPerformanceTransfer(
                practiceAverage: 6.2,
                concertAverage: 4.1,
                delta: -2.1,
                status: .significantDrop
            )
        )
    ]

    return ScrollView {
        PracticeAreaInsightsContent(
            metrics: metrics,
            rhythmMetric: PracticeRhythmCalculator.compute(
                sessions: (0..<30).compactMap { offset in
                    guard offset % 3 != 0 else { return nil }
                    return PracticeAreaMetricSessionInput(
                        id: UUID(),
                        startTime: Calendar.current.date(
                            byAdding: .day,
                            value: -offset,
                            to: Date()
                        ) ?? Date(),
                        duration: TimeInterval((25 + (offset % 4) * 15) * 60),
                        sessionType: .practice,
                        lastModified: Date()
                    )
                }
            ),
            activePracticeAreaCount: 2,
            onManagePracticeAreas: {}
        )
        .padding()
    }
    .background(Color("AppBackground"))
}
