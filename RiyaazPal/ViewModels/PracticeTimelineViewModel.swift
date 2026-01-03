//
//  PracticeTimelineViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-31.
//

import Foundation

@MainActor
final class PracticeTimelineViewModel: ObservableObject {
    
    @Published private(set) var sessions: [PracticeSession] = []
    
    func addSession(_ session: PracticeSession) {
        sessions.insert(session, at: 0)
    }
    
    func deleteSession(_ session: PracticeSession) {
        sessions.removeAll { $0.id == session.id }
    }
    
    func updateSession(_ updated: PracticeSession) {
        guard let index = sessions.firstIndex(where: { $0.id == updated.id }) else {
            return
        }
        sessions[index] = updated
    }
    
    var sessionsGroupedByDay: [(date: Date, sessions: [PracticeSession])] {
        let grouped = Dictionary(grouping:sessions) {
            Calendar.current.startOfDay(for: $0.startTime)
        }
        
        return grouped
            .sorted{$0.key > $1.key}
            .map{ (date: $0.key, sessions: $0.value) }
    }
    
    init() {
        loadDummyData()
    }

    private func loadDummyData() {
        sessions = [
            PracticeSession(
                startTime: Date(),
                duration: 45 * 60,
                notes: "Alap practice – slow tempo",
                tags: ["Raga Yaman", "Alap"]
            ),
            PracticeSession(
                startTime: Date().addingTimeInterval(-3600),
                duration: 30 * 60,
                notes: "Meend exercises",
                tags: ["Technique"]
            ),
            PracticeSession(
                startTime: Date().addingTimeInterval(-86_400),
                duration: 60 * 60,
                notes: "Full riyaaz session with tanpura",
                tags: ["Raga Bhairav"]
            )
        ]
    }

}

