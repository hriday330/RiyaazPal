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
    
    @Query(sort: \TagCategoryModel.order)
        private var tagCategories: [TagCategoryModel]
    
    @Query(filter: #Predicate<GoalEntity> { $0.isActive == true })
        private var activeGoals: [GoalEntity]

    
    @StateObject private var insightsViewModel = InsightsViewModel()
    @State private var mode: InsightsMode = .practice
    @State private var showProfile = false
    
    private var categorizer: TagCategorizer {
        TagCategorizer(categories: tagCategories)
    }
    
    private var recentSessions: [PracticeSession] {
        insightsViewModel.recentSessions(from: sessions)
    }
    
    private var practiceSessions: [PracticeSession] {
        recentSessions.filter { $0.resolvedSessionType == .practice }
    }

    private var recentConcertSessions: [PracticeSession] {
        recentSessions.filter { $0.resolvedSessionType == .concert }
    }
    
    private var concertSessions: [PracticeSession] {
        sessions.filter { $0.resolvedSessionType == .concert }
    }
    
    


    private var focusStats: FocusStats {
        insightsViewModel.focusStats(from: recentSessions, categorizer: categorizer)
    }
    
    private var consistencyStats: ConsistencyStats {
        insightsViewModel.consistencyStats(from: recentSessions)
    }
    
    private var patterns: [PracticePattern] {
        insightsViewModel.patterns(from: recentSessions, focusStats: focusStats, categorizer: categorizer)
    }
    
    private var practiceScore: Int {
        insightsViewModel.practiceScore(consistency: consistencyStats, patterns: patterns)
    }

    private var focusCategories: [TagCategory] {
        tagCategories
            .filter { $0.isFocusRelevant }
            .sorted { $0.order < $1.order }
            .map {
                TagCategory(
                    id: $0.id,
                    name: $0.name,
                    isFocusRelevant: $0.isFocusRelevant
                )
            }
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    header
                    insightsModeChips
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
            }.refreshable {
                await insightsViewModel.fetchReflectionInsight(
                    sessions: recentSessions,
                    goals: activeGoals
                )
            }
        }.task(id: insightsVersion) {
            await insightsViewModel.fetchReflectionInsight(sessions: recentSessions, goals: activeGoals)
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
    var practiceInsightsContent: some View {
        VStack{
            PracticeScoreMeter(
                score: practiceScore
            )
            ReflectionInsightSection(
                insight: insightsViewModel.reflectionInsight,
                isLoading: insightsViewModel.isLoadingInsight,
                error: insightsViewModel.insightError,
                onAddGoalsTapped: {
                    showProfile = true
                }
            )
            ConsistencySummarySection(consistencyStats: consistencyStats)
                .insightCard()
                .shadow(color: .black.opacity(0.08), radius: 10)
            FocusCarousel(focusStats: focusStats, categories: focusCategories)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color("CardBackground"))
                )
                .shadow(color: .black.opacity(0.08), radius: 10)
            
            notablePatterns
        }
    }
    
    var concertInsightsContent: some View {
        VStack(spacing: 16) {
            ConcertFrequencyCard(concerts: recentConcertSessions)
            ConcertConfidenceTrendCard(sessions: concertSessions)
            ConfidenceByRagaCard(sessions: concertSessions, categorizer: categorizer)
            RepertoireRepeatCard(sessions: recentConcertSessions, categorizer: categorizer)
            RepertoireNeglectCard(practiceSessions: practiceSessions, concertSessions: recentConcertSessions, categorizer: categorizer)
            
        }
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
                    ).shadow(color: .black.opacity(0.08), radius: 10)
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
    
    private var insightsVersion: InsightsVersion {
        insightsViewModel.insightsVersion(
            recentSessions: recentSessions
        )
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
