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
    
    @EnvironmentObject var router: TabRouter
    
    @Query(sort: \PracticeSession.startTime, order: .reverse)
        private var sessions: [PracticeSession]
    
    @Query(sort: \TagCategoryModel.order)
        private var tagCategories: [TagCategoryModel]
    
    @StateObject private var insightsViewModel = InsightsViewModel()
    
    private var categorizer: TagCategorizer {
        TagCategorizer(categories: tagCategories)
    }
    
    private var recentSessions: [PracticeSession] {
        insightsViewModel.recentSessions(from: sessions)
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
                    PracticeScoreMeter(
                        score: practiceScore
                    )
                    ReflectionInsightSection(
                        insight: insightsViewModel.reflectionInsight,
                        isLoading: insightsViewModel.isLoadingInsight,
                        error: insightsViewModel.insightError
                    )
                    consistencySummary
                        .shadow(color: .black.opacity(0.08), radius: 10)
                    FocusCarousel(focusStats: focusStats, categories: focusCategories)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color("CardBackground"))
                        )
                        .shadow(color: .black.opacity(0.08), radius: 10)
                    
                    notablePatterns
                    
                    
                }.scrollTransition(.interactive) { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1.0 : 0.94)
                        .offset(y: phase.isIdentity ? 0 : 6)
                    
                }
                
                .padding()
            }.refreshable {
                await insightsViewModel.fetchReflectionInsight(
                    sessions: recentSessions
                )
            }
        }.task(id: insightsVersion) {
            await insightsViewModel.fetchReflectionInsight(sessions: recentSessions)
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
    // TODO: extract to subcomponent
    var consistencySummary: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Consistency")
                        .font(.headline)
                    
                    Text("You practiced \(consistencyStats.practicedDays) out of the last \(consistencyStats.totalDays) days.")
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                    
                    if consistencyStats.streak > 1 {
                        Text("Current streak: \(consistencyStats.streak) days")
                            .font(.caption)
                            .foregroundStyle(Color("SecondaryText"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AccentColor").opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                Spacer()
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    router.selectedTab = .timeline
                } label: {
                    HStack(spacing: 4) {
                        Text("Practice")
                        Image(systemName: "play.fill")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("AccentColor"))
                    .clipShape(Capsule())
                }
            }
        
            GeometryReader { geo in
                let ratio = Double(consistencyStats.practicedDays) / Double(max(1, consistencyStats.totalDays))

                let progressColor: Color = {
                    switch consistencyStats.practicedDays {
                    case 0..<7:
                        return .red
                    case 7..<15:
                        return .orange
                    default:
                        return Color("AccentColor")
                    }
                }()

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 6)

                    Capsule()
                        .fill(progressColor)
                        .frame(
                            width: geo.size.width * CGFloat(ratio),
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.25), value: ratio)
                        .animation(.easeInOut(duration: 0.25), value: progressColor)
                }
            }

            .frame(height: 6)
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
