//
//  InsightsView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-07.
//

import Foundation
import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \PracticeSession.startTime, order: .reverse)
        private var sessions: [PracticeSession]
    
    private var recentSessions: [PracticeSession] {
        InsightWindowHelper.sessionsInWindow(sessions)
    }

    private var focusStats: FocusStats {
        FocusStatsCalculator.compute(sessions: recentSessions)
    }
    
    private var dateRange: DateRange {
        InsightWindowHelper.dateRange()
    }
    
    

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    practiceScoreCard
                    FocusCarousel(focusStats: focusStats)
                    consistencySummary
                    notablePatterns
                    suggestedDirection
                }
                .padding()
            }
        }
        .navigationTitle("Insights")
    }
}

private extension InsightsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Recent Practice")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryText"))

            Text(dateString)
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension InsightsView {
    var practiceScoreCard: some View {
        PracticeScoreMeter(
            score: 78,
            subtitle: "Consistent practice with strong technical focus"
        )
    }
}


private extension InsightsView {
    var consistencySummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Consistency")
                .font(.headline)

            Text("You practiced 5 out of the last 7 days.")
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
}


private extension InsightsView {
    var notablePatterns: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notable Patterns")
                .font(.headline)

            VStack(spacing: 10) {
                patternCard(
                    icon: "music.note",
                    title: "Focus Imbalance",
                    description: "Vilambit appeared in only one session this week."
                )

                patternCard(
                    icon: "clock",
                    title: "Fatigue Signal",
                    description: "Long sessions were often followed by shorter practice."
                )
            }
        }
    }

    func patternCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("AccentColor"))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
        )
    }
}

private extension InsightsView {
    var suggestedDirection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Direction")
                .font(.headline)

            Text("Consider dedicating a short session this week to vilambit alap to rebalance your practice.")
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("ActiveCardBackground"))
        )
    }
}

private extension InsightsView {
    private var dateString: String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(from: dateRange.start, to: dateRange.end)
    }
}

#Preview("Insights – Light") {
    NavigationStack {
        InsightsView()
    }
    .preferredColorScheme(.light)
}

#Preview("Insights – Dark") {
    NavigationStack {
        InsightsView()
    }
    .preferredColorScheme(.dark)
}
