//
//  ICloudSyncStatusMonitor.swift
//  RiyaazPal
//
//  Created by OpenAI on 2026-05-19.
//

import CoreData
import Foundation

@MainActor
final class ICloudSyncStatusMonitor: ObservableObject {
    @Published private(set) var isSyncing = false

    private var activeImportEventIDs: Set<UUID> = []
    private var isShowingTimelineSyncHint = false
    private var observer: NSObjectProtocol?
    private var timelineSyncHintTask: Task<Void, Never>?

    init(notificationCenter: NotificationCenter = .default) {
        observer = notificationCenter.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.handleCloudKitEventNotification(notification)
            }
        }
    }

    deinit {
        timelineSyncHintTask?.cancel()

        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func showTimelineSyncHint(duration: Duration = .seconds(12)) {
        guard RiyaazPalModelContainer.isICloudSyncEnabled else { return }

        isShowingTimelineSyncHint = true
        updateSyncingState()

        timelineSyncHintTask?.cancel()
        timelineSyncHintTask = Task { [weak self] in
            do {
                try await Task.sleep(for: duration)
            } catch {
                return
            }

            await MainActor.run {
                self?.isShowingTimelineSyncHint = false
                self?.updateSyncingState()
            }
        }
    }

    func showTimelineDataChangeHint() {
        showTimelineSyncHint(duration: .seconds(2))
    }

    private func handleCloudKitEventNotification(_ notification: Notification) {
        guard
            let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event,
            event.type == .import || event.type == .setup
        else { return }

        if event.endDate == nil {
            activeImportEventIDs.insert(event.identifier)
        } else {
            activeImportEventIDs.remove(event.identifier)
        }

        updateSyncingState()
    }

    private func updateSyncingState() {
        isSyncing = !activeImportEventIDs.isEmpty || isShowingTimelineSyncHint
    }
}
