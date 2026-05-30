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

    @AppStorage(FirstRunGuidanceKeys.insightsTip)
    private var hasSeenInsightsTip = false

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    header
                    insightsGuidanceCard
                    insightsModeChips
                    insightSummaryCard
                    if !insightsViewModel.hasLoadedMetrics {
                        insightsLoadingCard
                    } else if mode == .practice {
                        practiceInsightsContent
                    } else {
                        concertInsightsContent
                    }
                }
                .padding()
            }
        }

        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PracticeAreaInsightRoute.self) { route in
            if let metric = insightsViewModel.practiceAreaMetrics.first(where: { $0.id == route.metricID }) {
                PracticeAreaInsightDetailView(
                    metric: metric,
                    mode: .practice
                )
            }
        }
        .navigationDestination(for: ConcertPracticeAreaInsightRoute.self) { route in
            if let metric = insightsViewModel.practiceAreaMetrics.first(where: { $0.id == route.metricID }) {
                PracticeAreaInsightDetailView(
                    metric: metric,
                    mode: .concert
                )
            }
        }
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
        .onReceive(NotificationCenter.default.publisher(for: .practiceNudgeNotificationTapped)) { _ in
            showProfile = false
        }
        .task(id: metricsRefreshID) {
            insightsViewModel.loadMetrics(
                practiceAreas: practiceAreas,
                ratings: practiceAreaRatings,
                sessions: sessions,
                window: insightsViewModel.currentWindow,
                requestID: metricsRefreshID
            )
        }
        .task(id: summaryRefreshID) {
            await insightsViewModel.loadMetricSummary(
                metrics: insightsViewModel.practiceAreaMetrics,
                activePracticeAreaCount: insightsViewModel.activePracticeAreaCount,
                concertCount: insightsViewModel.concertCount,
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

    @ViewBuilder
    var insightsGuidanceCard: some View {
        if !hasSeenInsightsTip {
            FirstRunGuidanceCard(
                title: "Track what is changing",
                message: "Insights turns your reflection scores into trends, attention areas, and practice-to-concert comparisons.",
                systemImage: "chart.line.uptrend.xyaxis"
            ) { dismissInsightsGuidance() }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    func dismissInsightsGuidance() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            hasSeenInsightsTip = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

    var insightsLoadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()

            VStack(alignment: .leading, spacing: 4) {
                Text("Loading insights")
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryText"))

                Text("Preparing your practice-area trends.")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer()
        }
        .insightCard()
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    var practiceInsightsContent: some View {
        PracticeAreaInsightsContent(
            metrics: insightsViewModel.practiceAreaMetrics,
            rhythmMetric: insightsViewModel.practiceRhythmMetric,
            activePracticeAreaCount: insightsViewModel.activePracticeAreaCount,
            onManagePracticeAreas: {
                showProfile = true
            }
        )
    }
    
    var concertInsightsContent: some View {
        ConcertPracticeAreaInsightsContent(
            metrics: insightsViewModel.practiceAreaMetrics,
            activePracticeAreaCount: insightsViewModel.activePracticeAreaCount,
            concertCount: insightsViewModel.concertCount,
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

private extension InsightsView {
    private var dateString: String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(from: insightsViewModel.currentWindow.start, to: insightsViewModel.currentWindow.end)
    }

    private var metricsRefreshID: String {
        let latestSessionModified = sessions.map(\.lastModified).max()?.timeIntervalSince1970 ?? 0
        let latestRatingModified = practiceAreaRatings.map(\.lastModified).max()?.timeIntervalSince1970 ?? 0
        let practiceAreaValues = practiceAreas.map { area in
            [
                area.id.uuidString,
                area.name,
                "\(area.isActive)",
                "\(area.order)"
            ].joined(separator: ":")
        }.joined(separator: "|")

        return [
            "\(insightsViewModel.currentWindow.end.timeIntervalSince1970)",
            "\(sessions.count)",
            "\(latestSessionModified)",
            "\(practiceAreaRatings.count)",
            "\(latestRatingModified)",
            practiceAreaValues
        ].joined(separator: "#")
    }

    private var summaryRefreshID: String {
        let metricValues = insightsViewModel.practiceAreaMetrics.map { metric in
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
            "\(insightsViewModel.activePracticeAreaCount)",
            "\(insightsViewModel.concertCount)",
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
