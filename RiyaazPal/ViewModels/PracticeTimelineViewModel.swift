//
//  PracticeTimelineViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-31.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class PracticeTimelineViewModel: ObservableObject {

    @Published private(set) var sessions: [PracticeSession] = []
    @Published private(set) var isLoadingInitialPage = false
    @Published private(set) var isLoadingOlderPage = false
    @Published private(set) var hasMoreOlderSessions = true

    private let olderPageSize = 80
    private let initialLoadDays = 7

    func loadInitialPage(context: ModelContext) {
        guard sessions.isEmpty, !isLoadingInitialPage else { return }

        isLoadingInitialPage = true
        defer { isLoadingInitialPage = false }

        do {
            sessions = try fetchInitialWindow(context: context)
            hasMoreOlderSessions = !sessions.isEmpty
        } catch {
            sessions = []
            hasMoreOlderSessions = false
        }
    }

    func reloadFirstPage(context: ModelContext) {
        isLoadingInitialPage = true
        defer { isLoadingInitialPage = false }

        do {
            sessions = try fetchInitialWindow(context: context)
            hasMoreOlderSessions = !sessions.isEmpty
        } catch {
            hasMoreOlderSessions = false
        }
    }

    func loadOlderPageIfNeeded(
        currentGroupDate: Date,
        groups: [(date: Date, sessions: [PracticeSession])],
        context: ModelContext
    ) {
        guard groups.last?.date == currentGroupDate else { return }
        loadOlderPage(context: context)
    }

    func loadOlderPage(context: ModelContext) {
        guard hasMoreOlderSessions, !isLoadingOlderPage else { return }
        guard let oldestLoadedDate = sessions.last?.startTime else { return }

        isLoadingOlderPage = true
        defer { isLoadingOlderPage = false }

        do {
            let olderSessions = try fetchPage(
                olderThan: oldestLoadedDate,
                context: context
            )
            appendUniqueSessions(olderSessions)
            hasMoreOlderSessions = olderSessions.count == olderPageSize
        } catch {
            hasMoreOlderSessions = false
        }
    }

    func loadUntilMonthExists(
        _ month: Date,
        context: ModelContext,
        calendar: Calendar = .current
    ) {
        while hasMoreOlderSessions,
              !sessions.contains(where: { calendar.isDate($0.startTime, equalTo: month, toGranularity: .month) }) {
            let countBeforeLoad = sessions.count
            loadOlderPage(context: context)

            if sessions.count == countBeforeLoad {
                break
            }
        }
    }

    func removeSession(_ session: PracticeSession) {
        sessions.removeAll { $0.id == session.id }
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

    private func fetchInitialWindow(
        context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws -> [PracticeSession] {
        let startDate = calendar.date(
            byAdding: .day,
            value: -initialLoadDays,
            to: now
        ) ?? now

        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { session in
                session.startTime >= startDate
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    private func fetchPage(
        olderThan date: Date? = nil,
        context: ModelContext
    ) throws -> [PracticeSession] {
        var descriptor: FetchDescriptor<PracticeSession>

        if let date {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.startTime < date
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        }

        descriptor.fetchLimit = olderPageSize
        return try context.fetch(descriptor)
    }

    private func appendUniqueSessions(_ olderSessions: [PracticeSession]) {
        let existingIDs = Set(sessions.map(\.id))
        sessions.append(contentsOf: olderSessions.filter { !existingIDs.contains($0.id) })
        sessions.sort { $0.startTime > $1.startTime }
    }
}
