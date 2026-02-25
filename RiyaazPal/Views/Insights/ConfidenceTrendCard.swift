//
//  ConfidenceTrendCard.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-25.
//

import Foundation

import SwiftUI
import Charts

struct ConcertConfidenceTrendCard: View {
    let sessions: [PracticeSession]

    private var recentConfidence: [(date: Date, value: Int)] {
        sessions
            .filter { $0.resolvedSessionType == .concert }
            .compactMap { session in
                guard let confidence = session.resolvedConfidence else { return nil }
                return (session.startTime, confidence)
            }
            .sorted { $0.date < $1.date }
            .suffix(10)
    }

    private var dateRange: TimeInterval? {
        guard let first = recentConfidence.first?.date,
              let last = recentConfidence.last?.date else { return nil }
        return last.timeIntervalSince(first)
    }

    private var xAxisFormat: Date.FormatStyle {
        guard let range = dateRange else {
            return .dateTime.month()
        }

        // If concerts span more than ~6 months → show year
        if range > 60 * 60 * 24 * 180 {
            return .dateTime.year()
        } else {
            return .dateTime.month(.abbreviated)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Confidence Over Time")
                .font(.headline)

            if recentConfidence.isEmpty {
                Text("Confidence will appear here after a few concerts.")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
            } else {

                Chart {
                    ForEach(recentConfidence, id: \.date) { point in
                        LineMark(
                            x: .value("Concert", point.date),
                            y: .value("Confidence", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color("AccentColor"))

                        PointMark(
                            x: .value("Concert", point.date),
                            y: .value("Confidence", point.value)
                        )
                        .foregroundStyle(Color("AccentColor"))
                    }
                }
                .chartYScale(domain: 1...10)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [10]) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: xAxisValues) { value in
                        AxisValueLabel(format: xAxisFormat)
                    }
                }
                .frame(height: 160)

                if let insightText {
                    Text(insightText)
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.08), radius: 10)
    }

    private var insightText: String? {
        guard recentConfidence.count >= 3 else { return nil }

        let values = recentConfidence.map { Double($0.value) }

        let first = values.first!
        let last = values.last!
        let trend = last - first

        let mean = values.reduce(0, +) / Double(values.count)

        let variance = values
            .map { pow($0 - mean, 2) }
            .reduce(0, +) / Double(values.count)

        let stdDev = sqrt(variance)

        // realistic thresholds for 1–10 scale
        let isStable = stdDev < 1.2
        let isVeryStable = stdDev < 0.7

        // MARK: Trend + stability logic

        if trend >= 2 {
            return isStable
            ? "Confidence is trending upward across recent concerts."
            : "Confidence is improving, though performances vary."
        }

        if trend <= -2 {
            return isStable
            ? "Confidence has gradually dipped in recent concerts."
            : "Confidence has been inconsistent and trending downward."
        }

        if isVeryStable {
            return "Confidence has remained steady across performances."
        }

        if !isStable {
            return "Confidence varies from concert to concert."
        }

        // fallback — always return something
        return "Confidence has remained fairly consistent overall."
    }
    
    private var xAxisValues: [Date] {
        guard let first = recentConfidence.first?.date,
              let last = recentConfidence.last?.date else { return [] }

        var calendar = Calendar.current

        // If span > 6 months → show yearly ticks
        if let range = dateRange, range > 60 * 60 * 24 * 180 {
            let startYear = calendar.date(from: calendar.dateComponents([.year], from: first))!
            var ticks: [Date] = []

            var current = startYear
            while current <= last {
                ticks.append(current)
                current = calendar.date(byAdding: .year, value: 1, to: current)!
            }
            return ticks
        }

        let startMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: first))!
        var ticks: [Date] = []

        var current = startMonth
        while current <= last {
            ticks.append(current)
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }

        return ticks
    }
}

private extension View {
    func insightCard(background: Color = Color("CardBackground")) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
    }
}
