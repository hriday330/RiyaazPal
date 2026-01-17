//
//  ReflectionInsightsSection.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-12.
//

import Foundation
import SwiftUI

struct ReflectionInsightSection: View {
    let insight: ReflectionInsight?
    let isLoading: Bool
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reflection Insights")
                .font(.headline)

            content
        }
        .insightCard(background: Color("ActiveCardBackground"))
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            LoadingState()

        } else if let insight {
            InsightList(items: insight.items)

        } else if let error {
            ErrorState(message: error)

        } else {
            EmptyState()
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
                    .fill(Color("CardBackground"))
            ).shadow(color: .black.opacity(0.08), radius: 10)
    }
}

private struct InsightList: View {
    let items: [InsightItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items, id: \.item) { item in
                InsightRow(item: item)
            }
        }
    }
}

private struct InsightRow: View {
    let item: InsightItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: confidenceIcon)
                    .foregroundStyle(confidenceColor)

                Text(item.item)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("PrimaryText"))
            }

            Text(item.evidence)
                .font(.footnote)
                .foregroundStyle(Color("SecondaryText"))
                .padding(.leading, 24)
        }
    }

    private var confidenceIcon: String {
        switch item.confidence_delta {
        case let x where x > 0: return "arrow.up.right.circle.fill"
        case let x where x < 0: return "arrow.down.right.circle.fill"
        default: return "minus.circle.fill"
        }
    }

    private var confidenceColor: Color {
        switch item.confidence_delta {
        case let x where x > 0: return .green
        case let x where x < 0: return .red
        default: return .gray
        }
    }
}


private struct LoadingState: View {
    var body: some View {
        Text("Analyzing your reflections…")
            .font(.subheadline)
            .foregroundStyle(Color("SecondaryText"))
    }
}

private struct EmptyState: View {
    var body: some View {
        Text("Add reflections to see insights over time.")
            .font(.subheadline)
            .foregroundStyle(Color("SecondaryText"))
    }
}

private struct ErrorState: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(Color("SecondaryText"))
    }
}

#Preview("Loaded") {
    ReflectionInsightSection(
        insight: ReflectionInsight(
            items: [
                InsightItem(
                    item: "Bol taan clarity",
                    confidence_delta: 1,
                    evidence: "Felt smoother and more even across repetitions"
                ),
                InsightItem(
                    item: "Left-hand endurance",
                    confidence_delta: -1,
                    evidence: "Fatigue appeared earlier than usual in longer sessions"
                )
            ]
        ),
        isLoading: false,
        error: nil
    )
    .padding()
    .background(Color("AppBackground"))
}

#Preview("Loading") {
    ReflectionInsightSection(
        insight: nil,
        isLoading: true,
        error: nil
    )
    .padding()
    .background(Color("AppBackground"))
}

#Preview("Empty") {
    ReflectionInsightSection(
        insight: nil,
        isLoading: false,
        error: nil
    )
    .padding()
    .background(Color("AppBackground"))
}

#Preview("Error") {
    ReflectionInsightSection(
        insight: nil,
        isLoading: false,
        error: "Unable to analyze reflections. Please try again."
    )
    .padding()
    .background(Color("AppBackground"))
}

