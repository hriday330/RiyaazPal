//
//  InsightsViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-14.
//

import Foundation
import SwiftData

final class InsightsViewModel: ObservableObject {
    
    @Published var currentWindow: DateRange = InsightWindowHelper.dateRange()
    
    @Published var reflectionInsight: ReflectionInsight?
    @Published var isLoadingInsight = false
    @Published var insightError: String?
    
    func recentSessions(from sessions: [PracticeSession]) -> [PracticeSession] {
        InsightWindowHelper.sessionsInWindow(sessions)
    }
    
    func focusStats(from sessions: [PracticeSession], categorizer: TagCategorizer) -> FocusStats {
        FocusStatsCalculator.compute(sessions: sessions, categorizer: categorizer)
    }
    
    func consistencyStats(
        from sessions: [PracticeSession]
    ) -> ConsistencyStats {
        ConsistencyStatsCalculator.compute(
            sessions: sessions,
            dateRange: currentWindow
        )
    }
    
    func patterns(
        from sessions: [PracticeSession],
        focusStats: FocusStats,
        categorizer: TagCategorizer
    ) -> [PracticePattern] {
        PracticePatternCalculator.compute(
            sessions: sessions,
            focusStats: focusStats,
            categorizer: categorizer
        )
    }
    
    func practiceScore(
        consistency: ConsistencyStats,
        patterns: [PracticePattern]
    ) -> Int {
        PracticeScoreCalculator.compute(
            consistency: consistency,
            patterns: patterns
        )
    }
    
    private var insightTask: Task<Void, Never>?
    
    @MainActor
    func fetchReflectionInsight(sessions: [PracticeSession], goals: [GoalEntity]) async {
        insightTask?.cancel()
        
        guard !sessions.isEmpty else {
            reflectionInsight = nil
            return
        }
        insightTask = Task {
            isLoadingInsight = true
            insightError = nil
            
            do {
                let insight = try await ReflectionInsightService.generateInsight(
                    sessions: sessions,
                    goals: goals,
                    window: currentWindow
                )
                try Task.checkCancellation()
                
                reflectionInsight = insight
            } catch is CancellationError {
                return
            } catch {
                insightError = "Unable to analyze reflections. Please try again."
                reflectionInsight = nil
            }
            
            isLoadingInsight = false
        }
    }
    
    func insightsVersion(
        recentSessions: [PracticeSession]
    ) -> InsightsVersion {
        InsightsVersion(
            sessionCount: recentSessions.count,
            lastModified: recentSessions.map(\.lastModified).max(),
            rangeStart: currentWindow.start,
            rangeEnd: currentWindow.end
        )
    }
}

struct InsightsVersion: Hashable {
    let sessionCount: Int
    let lastModified: Date?
    let rangeStart: Date
    let rangeEnd: Date
}
