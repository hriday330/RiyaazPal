//
//  InsightsView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-07.
//

import Foundation
import SwiftUI
import SwiftData

enum InsightsMode {
    case practice
    case concerts
}

struct InsightsView: View {
    
    @EnvironmentObject var router: TabRouter
    
    @Query(sort: \PracticeSession.startTime, order: .reverse)
        private var sessions: [PracticeSession]
    
    @Query(sort: \PracticeAreaEntity.order)
        private var practiceAreas: [PracticeAreaEntity]

    @Query(sort: \PracticeAreaRatingEntity.createdAt)
        private var practiceAreaRatings: [PracticeAreaRatingEntity]

    
    @StateObject private var insightsViewModel = InsightsViewModel()
    @State private var mode: InsightsMode = .practice
    @State private var showProfile = false
    
    private var concertCount: Int {
        sessions.filter { $0.resolvedSessionType == .concert }.count
    }

    private var practiceAreaMetrics: [PracticeAreaMetric] {
        PracticeAreaMetricsCalculator.compute(
            practiceAreas: practiceAreas,
            ratings: practiceAreaRatings,
            sessions: sessions,
            now: insightsViewModel.currentWindow.end
        )
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    header
                    insightsModeChips
                    insightSummaryCard
                    if (mode == .practice){
                        practiceInsightsContent
                    } else {
                        concertInsightsContent
                    }
                    
            
                }.scrollTransition(.interactive) { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1.0 : 0.94)
                        .offset(y: phase.isIdentity ? 0 : 6)
                    
                }
                
                .padding()
            }
        }

        .navigationTitle("Insights")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showProfile = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .imageScale(.large)
                }
            }
        }.sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task(id: summaryRefreshID) {
            await insightsViewModel.loadMetricSummary(
                metrics: practiceAreaMetrics,
                activePracticeAreaCount: practiceAreas.filter(\.isActive).count,
                concertCount: concertCount,
                window: insightsViewModel.currentWindow,
                requestID: summaryRefreshID
            )
        }
    }
}


private extension InsightsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Recent \(mode == .practice ? "Practice" : "Concerts")")
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
    @ViewBuilder
    var insightSummaryCard: some View {
        if let summaryText = insightsViewModel.summaryText {
            VStack(alignment: .leading, spacing: 8) {
                Label("Overall Summary", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryText"))

                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .insightCard()
            .shadow(color: .black.opacity(0.08), radius: 10)
        }
    }

    var practiceInsightsContent: some View {
        PracticeAreaInsightsContent(
            metrics: practiceAreaMetrics,
            activePracticeAreaCount: practiceAreas.filter(\.isActive).count,
            onManagePracticeAreas: {
                showProfile = true
            }
        )
    }
    
    var concertInsightsContent: some View {
        ConcertPracticeAreaInsightsContent(
            metrics: practiceAreaMetrics,
            activePracticeAreaCount: practiceAreas.filter(\.isActive).count,
            concertCount: concertCount,
            onManagePracticeAreas: {
                showProfile = true
            }
        )
    }


}

private extension InsightsView {
    var insightsModeChips: some View {
        HStack(spacing: 8) {
            FilterChip(
                title: "Practice",
                isSelected: mode == .practice
            ) {
                mode = .practice
            }

            FilterChip(
                title: "Concerts",
                isSelected: mode == .concerts
            ) {
                mode = .concerts
            }

            Spacer()
        }
        .padding(.horizontal)
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

private extension InsightsView {
    private var dateString: String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(from: insightsViewModel.currentWindow.start, to: insightsViewModel.currentWindow.end)
    }

    private var summaryRefreshID: String {
        let metricValues = practiceAreaMetrics.map { metric in
            [
                metric.id,
                metric.areaName,
                "\(metric.isActive)",
                "\(metric.latestScore ?? -1)",
                "\(metric.sevenDayAverage ?? -1)",
                "\(metric.previousSevenDayAverage ?? -1)",
                "\(metric.thirtyDayAverage ?? -1)",
                "\(metric.trendDirection)",
                "\(metric.ratedSessionCount)",
                "\(metric.daysSincePracticed ?? -1)",
                "\(metric.isNeglected)",
                "\(metric.volatility ?? -1)",
                "\(metric.practice.latestScore ?? -1)",
                "\(metric.practice.averageScore ?? -1)",
                "\(metric.practice.ratedSessionCount)",
                "\(metric.concert.latestScore ?? -1)",
                "\(metric.concert.averageScore ?? -1)",
                "\(metric.concert.ratedSessionCount)",
                "\(metric.performanceTransfer.delta ?? -99)",
                "\(metric.performanceTransfer.status)"
            ].joined(separator: ":")
        }.joined(separator: "|")

        return [
            "\(insightsViewModel.currentWindow.start.timeIntervalSince1970)",
            "\(insightsViewModel.currentWindow.end.timeIntervalSince1970)",
            "\(practiceAreas.filter(\.isActive).count)",
            "\(concertCount)",
            metricValues
        ].joined(separator: "#")
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

#Preview("Insights – Concert Imbalance") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    PreviewData.insertConcertImbalance(into: context)

    return NavigationStack {
        InsightsView()
    }
    .modelContainer(container)
}
