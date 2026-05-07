//
//  PracticeAreaInsightsContent.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-04.
//

import SwiftUI

struct PracticeAreaInsightsContent: View {
    let metrics: [PracticeAreaMetric]
    let activePracticeAreaCount: Int
    let onManagePracticeAreas: () -> Void

    private var activeMetrics: [PracticeAreaMetric] {
        metrics.filter(\.isActive)
    }

    private var ratedMetrics: [PracticeAreaMetric] {
        metrics.filter { $0.practice.ratedSessionCount > 0 }
    }

    private var attentionMetrics: [PracticeAreaMetric] {
        activeMetrics
            .filter { metric in
                metric.isNeglected
                || metric.trendDirection == .declining
                || metric.performanceTransfer.status == .significantDrop
            }
            .sorted(by: attentionSort)
    }

    private var improvingMetrics: [PracticeAreaMetric] {
        activeMetrics
            .filter { $0.trendDirection == .improving }
            .sorted { lhs, rhs in
                (lhs.sevenDayAverage ?? 0) > (rhs.sevenDayAverage ?? 0)
            }
    }

    var body: some View {
        VStack(spacing: 16) {
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
                        NavigationLink {
                            PracticeAreaInsightDetailView(
                                metric: metric,
                                mode: .practice
                            )
                        } label: {
                            PracticeAreaMetricCard(metric: metric)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func attentionSort(
        lhs: PracticeAreaMetric,
        rhs: PracticeAreaMetric
    ) -> Bool {
        attentionScore(lhs) > attentionScore(rhs)
    }

    private func attentionScore(_ metric: PracticeAreaMetric) -> Int {
        var score = 0
        if metric.isNeglected { score += 4 }
        if metric.performanceTransfer.status == .significantDrop { score += 3 }
        if metric.trendDirection == .declining { score += 2 }
        if metric.daysSincePracticed ?? 0 > 10 { score += 1 }
        return score
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
        .shadow(color: .black.opacity(0.08), radius: 10)
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
        .shadow(color: .black.opacity(0.08), radius: 10)
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
        .shadow(color: .black.opacity(0.08), radius: 10)
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
        .shadow(color: .black.opacity(0.08), radius: 10)
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
            activePracticeAreaCount: 2,
            onManagePracticeAreas: {}
        )
        .padding()
    }
    .background(Color("AppBackground"))
}
