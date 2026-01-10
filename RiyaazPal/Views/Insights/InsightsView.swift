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
    
    
    private var dateRange: DateRange {
        InsightWindowHelper.dateRange()
    }
    
    private var recentSessions: [PracticeSession] {
        InsightWindowHelper.sessionsInWindow(sessions)
    }

    private var focusStats: FocusStats {
        FocusStatsCalculator.compute(sessions: recentSessions)
    }
    
    private var consistencyStats: ConsistencyStats {
        ConsistencyStatsCalculator.compute(sessions: recentSessions, dateRange: dateRange)
    }
    
    private var patterns: [PracticePattern] {
        PracticePatternCalculator.compute(sessions: recentSessions, focusStats: focusStats)
    }
    
    private var practiceScore: Int {
        PracticeScoreCalculator.compute(
            consistency: consistencyStats,
            patterns: patterns
        )
    }

    
    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
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
            score: practiceScore
        )
    }
}


private extension InsightsView {
    var consistencySummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Consistency")
                .font(.headline)

            Text("You practiced \(consistencyStats.practicedDays) out of the last \(consistencyStats.totalDays) days.")
            .font(.subheadline)
            .foregroundStyle(Color("SecondaryText"))

            if consistencyStats.streak > 1 {
                Text("Current streak: \(consistencyStats.streak) days")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }
        }
        .insightCard()
    }
}


private extension InsightsView {
    var notablePatterns: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notable Patterns")
                .font(.headline)

            VStack(spacing: 10) {
                
                if (patterns.isEmpty) {
                    Text("No major patterns detected this period. Keep up the balanced riyaz!")
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                }
                ForEach(patterns, id:\.id) { pattern in
                    patternCard(
                        icon: pattern.icon,
                        title: pattern.title,
                        description: pattern.description
                    )
                }
            }
        }.insightCard()
    }

    func patternCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("AccentColor"))
                .frame(width: 20, alignment: .top)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer(minLength:15)
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
        .insightCard(background: Color("ActiveCardBackground"))
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

private extension InsightsView {
    private var dateString: String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(from: dateRange.start, to: dateRange.end)
    }
}

#Preview("Insights – Light") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    PreviewData.insertSessions(into: context)
    return NavigationStack {
        InsightsView()
        
    }
    .modelContainer(container)
    .preferredColorScheme(.light)
}

#Preview("Insights – Light - Perfect") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    PreviewData.insertPerfectMonth(into: context)
    return NavigationStack {
        InsightsView()
        
    }
    .modelContainer(container)
    .preferredColorScheme(.light)
}

#Preview("Insights – Dark") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext
    PreviewData.insertSessions(into: context)

    return NavigationStack {
        InsightsView()
        
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
