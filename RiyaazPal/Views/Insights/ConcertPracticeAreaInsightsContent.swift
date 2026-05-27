//
//  ConcertPracticeAreaInsightsContent.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-05.
//

import SwiftUI

private struct ConcertPracticeAreaInsightRoute: Hashable {
    let metricID: String
}

struct ConcertPracticeAreaInsightsContent: View {
    let metrics: [PracticeAreaMetric]
    let activePracticeAreaCount: Int
    let concertCount: Int
    let onManagePracticeAreas: () -> Void

    private var activeMetrics: [PracticeAreaMetric] {
        metrics.filter(\.isActive)
    }

    private var concertRatedMetrics: [PracticeAreaMetric] {
        metrics.filter { $0.concert.ratedSessionCount > 0 }
    }

    private var transferReadyMetrics: [PracticeAreaMetric] {
        activeMetrics.filter {
            $0.performanceTransfer.status != .insufficientData
        }
    }

    private var dropMetrics: [PracticeAreaMetric] {
        transferReadyMetrics
            .filter { $0.performanceTransfer.status == .significantDrop }
            .sorted { lhs, rhs in
                (lhs.performanceTransfer.delta ?? 0) < (rhs.performanceTransfer.delta ?? 0)
            }
    }

    private var maintainedMetrics: [PracticeAreaMetric] {
        transferReadyMetrics
            .filter { $0.performanceTransfer.status == .maintained }
            .sorted { lhs, rhs in
                (lhs.concert.averageScore ?? 0) > (rhs.concert.averageScore ?? 0)
            }
    }

    private var liftMetrics: [PracticeAreaMetric] {
        transferReadyMetrics
            .filter { $0.performanceTransfer.status == .concertLift }
            .sorted { lhs, rhs in
                (lhs.performanceTransfer.delta ?? 0) > (rhs.performanceTransfer.delta ?? 0)
            }
    }

    var body: some View {
        VStack(spacing: 16) {
            if activePracticeAreaCount == 0 {
                ConcertPracticeAreaEmptyState(
                    title: "No practice areas yet",
                    message: "Add practice areas from Profile to compare practice and concert execution.",
                    buttonTitle: "Add Practice Areas",
                    onButtonTapped: onManagePracticeAreas
                )
            } else if concertRatedMetrics.isEmpty {
                ConcertPracticeAreaEmptyState(
                    title: "No concert ratings yet",
                    message: "Reflect on concerts to see performance scores for each practice area.",
                    buttonTitle: "Manage Practice Areas",
                    onButtonTapped: onManagePracticeAreas
                )
            } else {
                ConcertPracticeAreaOverviewCard(
                    metrics: activeMetrics,
                    concertCount: concertCount
                )

                if !dropMetrics.isEmpty || !liftMetrics.isEmpty || !maintainedMetrics.isEmpty {
                    ConcertPracticeAreaHighlightsCard(
                        dropMetrics: Array(dropMetrics.prefix(3)),
                        liftMetrics: Array(liftMetrics.prefix(3)),
                        maintainedMetrics: Array(maintainedMetrics.prefix(3))
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Concert Areas")
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryText"))

                    ForEach(metrics) { metric in
                        NavigationLink(value: ConcertPracticeAreaInsightRoute(metricID: metric.id)) {
                            ConcertPracticeAreaMetricCard(metric: metric)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationDestination(for: ConcertPracticeAreaInsightRoute.self) { route in
            if let metric = metrics.first(where: { $0.id == route.metricID }) {
                PracticeAreaInsightDetailView(
                    metric: metric,
                    mode: .concert
                )
            }
        }
    }
}

private struct ConcertPracticeAreaOverviewCard: View {
    let metrics: [PracticeAreaMetric]
    let concertCount: Int

    private var latestConcertAverage: Double? {
        let scores = metrics.compactMap(\.concert.latestScore)
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    private var concertRatedAreaCount: Int {
        metrics.filter { $0.concert.ratedSessionCount > 0 }.count
    }

    private var significantDropCount: Int {
        metrics.filter {
            $0.performanceTransfer.status == .significantDrop
        }.count
    }

    private var liftCount: Int {
        metrics.filter {
            $0.performanceTransfer.status == .concertLift
        }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Concert Area Health")
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryText"))

                    Text("Average of the latest concert scores for active practice areas.")
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
                overviewMetric(value: "\(concertCount)", label: "Concerts")
                overviewMetric(value: "\(concertRatedAreaCount)", label: "Rated areas")
                overviewMetric(value: "\(significantDropCount)", label: "Drops")
                overviewMetric(value: "\(liftCount)", label: "Lifts")
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.08), radius: 10)
    }

    private var scoreText: String {
        guard let latestConcertAverage else { return "-" }
        return "\(latestConcertAverage.formatted(.number.precision(.fractionLength(1))))/10"
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

private struct ConcertPracticeAreaHighlightsCard: View {
    let dropMetrics: [PracticeAreaMetric]
    let liftMetrics: [PracticeAreaMetric]
    let maintainedMetrics: [PracticeAreaMetric]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Practice To Stage")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            if !dropMetrics.isEmpty {
                ConcertPracticeAreaHighlightGroup(
                    icon: "exclamationmark.triangle.fill",
                    title: "Dropping in concert",
                    metrics: dropMetrics,
                    summary: dropSummary
                )
            }

            if !maintainedMetrics.isEmpty {
                ConcertPracticeAreaHighlightGroup(
                    icon: "checkmark.circle.fill",
                    title: "Holding up in concert",
                    metrics: maintainedMetrics,
                    summary: maintainedSummary
                )
            }

            if !liftMetrics.isEmpty {
                ConcertPracticeAreaHighlightGroup(
                    icon: "arrow.up.forward.circle.fill",
                    title: "Stronger in concert",
                    metrics: liftMetrics,
                    summary: liftSummary
                )
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.08), radius: 10)
    }

    private func dropSummary(for metric: PracticeAreaMetric) -> String {
        guard let delta = metric.performanceTransfer.delta else {
            return "Concert average is trailing practice."
        }

        return "\(abs(delta).formatted(.number.precision(.fractionLength(1)))) lower than practice."
    }

    private func liftSummary(for metric: PracticeAreaMetric) -> String {
        guard let delta = metric.performanceTransfer.delta else {
            return "Concert average is higher than practice."
        }

        return "\(delta.formatted(.number.precision(.fractionLength(1)))) higher than practice."
    }

    private func maintainedSummary(for metric: PracticeAreaMetric) -> String {
        guard let average = metric.concert.averageScore else {
            return "Concert scores are holding steady."
        }

        return "Concert average is \(average.formatted(.number.precision(.fractionLength(1))))/10."
    }
}

private struct ConcertPracticeAreaHighlightGroup: View {
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

private struct ConcertPracticeAreaMetricCard: View {
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
                Text(latestConcertScoreText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AccentColor"))

                ConcertPracticeAreaStatusChip(
                    icon: metric.performanceTransfer.status.iconName,
                    text: metric.performanceTransfer.status.label,
                    tint: metric.performanceTransfer.status.tint
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
        let concertCount = metric.concert.ratedSessionCount

        guard concertCount > 0 else {
            return "No concert ratings yet"
        }

        let noun = concertCount == 1 ? "concert rating" : "concert ratings"
        let transferStatus = metric.performanceTransfer.status == .insufficientData
            ? "more data needed for comparison"
            : "practice comparison ready"

        return "\(concertCount) \(noun) - \(transferStatus)"
    }

    private var latestConcertScoreText: String {
        guard let score = metric.concert.latestScore else { return "-" }
        return "\(score)/10"
    }

}

private struct ConcertPracticeAreaStatusChip: View {
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

private struct ConcertPracticeAreaEmptyState: View {
    let title: String
    let message: String
    let buttonTitle: String
    let onButtonTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "music.mic")
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

private extension PracticeAreaPerformanceTransferStatus {
    var label: String {
        switch self {
        case .significantDrop:
            return "Concert drop"
        case .concertLift:
            return "Concert lift"
        case .maintained:
            return "Maintained"
        case .inconclusive:
            return "Mixed signal"
        case .insufficientData:
            return "Need more data"
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

#Preview("Concert Practice Area Insights") {
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
                latestScore: 8,
                averageScore: 7.7,
                ratedSessionCount: 3,
                volatility: 0.6
            ),
            performanceTransfer: PracticeAreaPerformanceTransfer(
                practiceAverage: 8.1,
                concertAverage: 7.7,
                delta: -0.4,
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
                latestScore: 7,
                averageScore: 6.4,
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
                practiceAverage: 6.4,
                concertAverage: 4.1,
                delta: -2.3,
                status: .significantDrop
            )
        )
    ]

    return ScrollView {
        ConcertPracticeAreaInsightsContent(
            metrics: metrics,
            activePracticeAreaCount: 2,
            concertCount: 4,
            onManagePracticeAreas: {}
        )
        .padding()
    }
    .background(Color("AppBackground"))
}
