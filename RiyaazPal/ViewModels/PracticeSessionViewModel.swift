//
//  PracticeSessionViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-31.
//

import Foundation
import ActivityKit

@MainActor
final class PracticeSessionViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isSessionActive: Bool = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published var notes: String = ""
    @Published var tags: [String] = []

    // MARK: - Private State

    private var startTime: Date?
    private var timer: Timer?
    
    init() {
        checkActiveSession()
    }

    // MARK: - Public API

    func startSession() {
        guard !isSessionActive else { return }

        isSessionActive = true
        startTime = Date()
        elapsedTime = 0

        startTimer()
        UserDefaults.standard.set(startTime, forKey: "session_start_time")
        startLiveActivity()
    }

    func endSession() -> PracticeSession? {
        guard isSessionActive, let startTime else { return nil }

        stopTimer()
        isSessionActive = false

        Task {
            await endLiveActivity()
            }
        let session = PracticeSession(
            startTime: startTime,
            duration: elapsedTime,
            notes: notes.isEmpty ? defaultTitle(for: startTime) : notes,
            tags: tags
        )

        resetDraft()
        return session
    }

    

    private func checkActiveSession() {
        if let activity = Activity<PracticeTimerActivityAttributes>.activities.first {
            isSessionActive = true
            startTime = UserDefaults.standard.object(forKey: "session_start_time") as? Date
            if let start = startTime {
                self.elapsedTime = Date().timeIntervalSince(start)
                startTimer()
            }
        }
    }
    
    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.elapsedTime += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Reset

    private func resetDraft() {
        startTime = nil
        elapsedTime = 0
        notes = ""
        tags = []
    }
    
    private func defaultTitle(for startTime: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm:ss a"
        return "Practice – \(formatter.string(from: startTime))"
    }
    
    private func startLiveActivity() {

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = PracticeTimerActivityAttributes(
            title: "Practice Session"
        )

        let state = PracticeTimerActivityAttributes.ContentState(
            startTime: Date()
        )

        let content = ActivityContent(
            state: state,
            staleDate: nil
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content
            )
            print("Started Live Activity:", activity.id)

        } catch {
            print("Failed to start Live Activity:", error)
        }
    }

    private func endLiveActivity() async {

        for activity in Activity<PracticeTimerActivityAttributes>.activities {

            let finalState = PracticeTimerActivityAttributes.ContentState(
                startTime: Date()
            )

            let finalContent = ActivityContent(
                state: finalState,
                staleDate: nil
            )

            await activity.end(
                finalContent,
                dismissalPolicy: .immediate
            )
        }
    }

}

