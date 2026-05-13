//
//  PracticeAreaInsightDetailView.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-05.
//

import Charts
import SwiftUI

enum PracticeAreaInsightDetailMode {
    case practice
    case concert
}

struct PracticeAreaInsightDetailView: View {
    let metric: PracticeAreaMetric
    let mode: PracticeAreaInsightDetailMode

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    scoreHistoryCard
                    if mode == .practice {
                        practiceTrendCard
                    } else {
                        concertTransferCard
                    }
                    splitCard
                    stabilityCard
                }
                .padding()
            }
        }
        .navigationTitle(metric.areaName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension PracticeAreaInsightDetailView {
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(mode == .practice ? "Practice Detail" : "Concert Detail")
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryText"))

                    Text(headerSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }

                Spacer()

                Text(primaryScoreText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AccentColor"))
            }

            HStack(spacing: 10) {
                DetailStatPill(label: "Total scores", value: "\(metric.ratedSessionCount)")
                DetailStatPill(label: "Practice", value: "\(metric.practice.ratedSessionCount)")
                DetailStatPill(label: "Concert", value: "\(metric.concert.ratedSessionCount)")
            }
        }
        .detailCard()
    }

    var scoreHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            DetailSectionHeader(
                title: "Scores Over Time",
                icon: "chart.xyaxis.line",
                tint: scoreHistoryTint
            )

            if scoreHistoryPoints.isEmpty {
                Text("No scored sessions yet.")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            } else {
                Chart(scoreHistoryPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(scoreHistoryTint)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .symbolSize(34)
                    .foregroundStyle(scoreHistoryTint)
                }
                .chartYScale(domain: 1...10)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color("SecondaryText").opacity(0.12))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                            .foregroundStyle(Color("SecondaryText"))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: [1, 5, 10]) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color("SecondaryText").opacity(0.12))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(Color("SecondaryText"))
                    }
                }
                .frame(height: 190)
            }
        }
        .detailCard()
    }

    var practiceTrendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            DetailSectionHeader(
                title: "Practice Trend",
                icon: metric.trendDirection.iconName,
                tint: metric.trendDirection.tint
            )

            HStack(spacing: 10) {
                DetailStatPill(label: "7-day", value: averageText(metric.sevenDayAverage))
                DetailStatPill(label: "Previous 7", value: averageText(metric.previousSevenDayAverage))
                DetailStatPill(label: "30-day", value: averageText(metric.thirtyDayAverage))
            }

            DetailStatusRow(
                icon: metric.trendDirection.iconName,
                title: metric.trendDirection.label,
                value: trendExplanation,
                tint: metric.trendDirection.tint
            )

            DetailStatusRow(
                icon: metric.isNeglected ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                title: metric.isNeglected ? "Needs attention" : "Recently touched",
                value: daysSinceText,
                tint: metric.isNeglected ? .red : .green
            )
        }
        .detailCard()
    }

    var concertTransferCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            DetailSectionHeader(
                title: "Practice To Concert",
                icon: metric.performanceTransfer.status.iconName,
                tint: metric.performanceTransfer.status.tint
            )

            HStack(spacing: 10) {
                DetailStatPill(label: "Concert avg", value: averageText(metric.concert.averageScore))
                DetailStatPill(label: "Practice avg", value: averageText(metric.practice.averageScore))
                DetailStatPill(label: "Delta", value: deltaText)
            }

            DetailStatusRow(
                icon: metric.performanceTransfer.status.iconName,
                title: metric.performanceTransfer.status.label,
                value: transferExplanation,
                tint: metric.performanceTransfer.status.tint
            )
        }
        .detailCard()
    }

    var splitCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            DetailSectionHeader(
                title: "Score Split",
                icon: "rectangle.split.2x1.fill",
                tint: Color("AccentColor")
            )

            HStack(spacing: 10) {
                contextColumn(title: "Practice", context: metric.practice)
                contextColumn(title: "Concert", context: metric.concert)
            }
        }
        .detailCard()
    }

    var stabilityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            DetailSectionHeader(
                title: "Stability",
                icon: "waveform.path.ecg",
                tint: volatilityTint(metric.volatility)
            )

            HStack(spacing: 10) {
                DetailStatPill(label: "Overall", value: volatilityText(metric.volatility))
                DetailStatPill(label: "Practice", value: volatilityText(metric.practice.volatility))
                DetailStatPill(label: "Concert", value: volatilityText(metric.concert.volatility))
            }

            DetailStatusRow(
                icon: volatilityIcon(metric.volatility),
                title: stabilityLabel(metric.volatility),
                value: stabilityExplanation(metric.volatility),
                tint: volatilityTint(metric.volatility)
            )

            Text("Volatility shows how much the scores move around. Lower volatility means this area is scoring more consistently.")
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
        }
        .detailCard()
    }
}

private extension PracticeAreaInsightDetailView {
    var headerSubtitle: String {
        if !metric.isActive {
            return "Archived area with historical ratings."
        }

        switch mode {
        case .practice:
            return "Practice score detail across recent and historical ratings."
        case .concert:
            return "Concert execution detail compared with practice scores."
        }
    }

    var primaryScoreText: String {
        switch mode {
        case .practice:
            guard let score = metric.latestScore else { return "-" }
            return "\(score)/10"
        case .concert:
            guard let score = metric.concert.latestScore else { return "-" }
            return "\(score)/10"
        }
    }

    var scoreHistoryPoints: [PracticeAreaScorePoint] {
        metric.scoreHistory.filter { point in
            switch mode {
            case .practice:
                return point.sessionType == .practice
            case .concert:
                return point.sessionType == .concert
            }
        }
    }

    var scoreHistoryTint: Color {
        switch mode {
        case .practice:
            return Color("AccentColor")
        case .concert:
            return .green
        }
    }

    var daysSinceText: String {
        guard let days = metric.daysSincePracticed else {
            return "No scored sessions yet."
        }

        if days == 0 {
            return "Scored today."
        }

        return "Last scored \(days) days ago."
    }

    var trendExplanation: String {
        switch metric.trendDirection {
        case .improving:
            return "The current 7-day average is meaningfully higher than the previous 7-day average."
        case .declining:
            return "The current 7-day average is meaningfully lower than the previous 7-day average."
        case .stable:
            return "The current 7-day average is close to the previous 7-day average."
        case .insufficientData:
            return "More ratings are needed before a trend can be detected."
        }
    }

    var transferExplanation: String {
        switch metric.performanceTransfer.status {
        case .significantDrop:
            return "Concert average is more than 1.5 points lower than practice average."
        case .concertLift:
            return "Concert average is more than 1.5 points higher than practice average."
        case .maintained:
            return "Concert average is within 1.5 points of practice average."
        case .inconclusive:
            return "There is enough data, but the difference is not a clear drop, lift, or maintained signal."
        case .insufficientData:
            return "Needs at least 4 practice scores and 3 concert scores for comparison."
        }
    }

    var deltaText: String {
        guard let delta = metric.performanceTransfer.delta else { return "-" }
        let formatted = abs(delta).formatted(.number.precision(.fractionLength(1)))
        return delta < 0 ? "-\(formatted)" : "+\(formatted)"
    }

    func averageText(_ value: Double?) -> String {
        guard let value else { return "-" }
        return "\(value.formatted(.number.precision(.fractionLength(1))))/10"
    }

    func volatilityText(_ value: Double?) -> String {
        guard let value else { return "-" }
        return value.formatted(.number.precision(.fractionLength(1)))
    }

    func volatilityTint(_ value: Double?) -> Color {
        guard let value else { return Color("SecondaryText") }

        switch value {
        case ..<0.8:
            return .green
        case ..<1.6:
            return .orange
        default:
            return .red
        }
    }

    func stabilityLabel(_ value: Double?) -> String {
        guard let value else { return "Stability needs more data" }

        switch value {
        case ..<0.8:
            return "Stable"
        case ..<1.6:
            return "Moderately variable"
        default:
            return "Highly variable"
        }
    }

    func stabilityExplanation(_ value: Double?) -> String {
        guard let value else {
            return "At least two scores are needed to measure volatility."
        }

        switch value {
        case ..<0.8:
            return "Scores are staying close together."
        case ..<1.6:
            return "Scores move around a bit from session to session."
        default:
            return "Scores are swinging noticeably across sessions."
        }
    }

    func volatilityIcon(_ value: Double?) -> String {
        guard let value else { return "questionmark.circle.fill" }

        switch value {
        case ..<0.8:
            return "checkmark.circle.fill"
        case ..<1.6:
            return "waveform.path.ecg"
        default:
            return "exclamationmark.triangle.fill"
        }
    }

    func contextColumn(
        title: String,
        context: PracticeAreaContextMetric
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryText"))

            DetailStatPill(label: "Latest", value: context.latestScore.map { "\($0)/10" } ?? "-")
            DetailStatPill(label: "Average", value: averageText(context.averageScore))
            DetailStatPill(label: "Scores", value: "\(context.ratedSessionCount)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DetailSectionHeader: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(tint)
    }
}

private struct DetailStatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryText"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color("SecondaryText"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("AppBackground"))
        )
    }
}

private struct DetailStatusRow: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("PrimaryText"))

                Text(value)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }
        }
    }
}

private extension View {
    func detailCard(background: Color = Color("CardBackground")) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(background)
            )
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
