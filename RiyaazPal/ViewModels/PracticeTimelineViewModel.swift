//
//  PracticeTimelineViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-31.
//

import Foundation
import SwiftUI

@MainActor
final class PracticeTimelineViewModel: ObservableObject {

    @Published private(set) var loadedStartDate: Date

    private let calendar: Calendar
    private let initialWindowDays = 30
    private var lastOlderWindowTriggerDate: Date?

    init(calendar: Calendar = .current, now: Date = Date()) {
        self.calendar = calendar
        loadedStartDate = calendar.date(
            byAdding: .day,
            value: -initialWindowDays,
            to: now
        ) ?? now
    }

    func loadOlderWindowIfNeeded(
        currentGroupDate: Date,
        groups: [(date: Date, sessions: [PracticeSession])]
    ) {
        guard groups.last?.date == currentGroupDate else { return }
        guard lastOlderWindowTriggerDate != currentGroupDate else { return }
        lastOlderWindowTriggerDate = currentGroupDate

        loadOlderWindow()
    }

    func loadOlderWindow() {
        let currentStartOfMonth = calendar.startOfMonth(for: loadedStartDate)
        loadedStartDate = calendar.date(
            byAdding: .month,
            value: -1,
            to: currentStartOfMonth
        ) ?? loadedStartDate
    }

    func loadWindowIncludingMonth(_ month: Date) {
        let monthStart = calendar.startOfMonth(for: month)
        guard monthStart < loadedStartDate else { return }
        loadedStartDate = monthStart
    }

    func groupedByDay(
            from sessions: [PracticeSession]
        ) -> [(date: Date, sessions: [PracticeSession])] {

            let grouped = Dictionary(grouping: sessions) {
                Calendar.current.startOfDay(for: $0.startTime)
            }

            return grouped
                .sorted { $0.key > $1.key }
                .map { (date: $0.key, sessions: $0.value) }
        }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
