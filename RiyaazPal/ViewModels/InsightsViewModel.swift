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
    
    func focusStats(from sessions: [PracticeSession]) -> FocusStats {
        FocusStatsCalculator.compute(sessions: sessions)
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
        focusStats: FocusStats
    ) -> [PracticePattern] {
        PracticePatternCalculator.compute(
            sessions: sessions,
            focusStats: focusStats
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
    
    
    @MainActor
    func fetchReflectionInsight(
        sessions: [PracticeSession]
    ) async {
        guard !sessions.isEmpty else { return }
        
        isLoadingInsight = true
        insightError = nil
        
        do {
            let insight = try await ReflectionInsightService.generateInsight(
                sessions: sessions,
                window: currentWindow
            )
            
            reflectionInsight = insight
        } catch {
            insightError = "Unable to analyze reflections. Please try again."
            reflectionInsight = nil
        }
        
        isLoadingInsight = false
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
