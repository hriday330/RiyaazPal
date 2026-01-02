//
//  PracticeSessionViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-31.
//

import Foundation

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

    // MARK: - Public API

    func startSession() {
        guard !isSessionActive else { return }

        isSessionActive = true
        startTime = Date()
        elapsedTime = 0

        startTimer()
    }

    func endSession() -> PracticeSession? {
        guard isSessionActive, let startTime else { return nil }

        stopTimer()
        isSessionActive = false

        let session = PracticeSession(
            startTime: startTime,
            duration: elapsedTime,
            notes: notes,
            tags: tags
        )

        resetDraft()
        return session
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
}
