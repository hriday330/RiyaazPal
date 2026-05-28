//
//  ICloudSyncStatusMonitor.swift
//  RiyaazPal
//
//  Created by OpenAI on 2026-05-19.
//

import Foundation
import Network

@MainActor
final class ICloudSyncStatusMonitor: ObservableObject {
    @Published private(set) var isSyncing = false

    private var isNetworkOnline = false
    private var isShowingTimelineSyncHint = false
    private var shouldShowInitialHintWhenOnline = false
    private var timelineSyncHintTask: Task<Void, Never>?
    private let userDefaults: UserDefaults
    private let networkMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "com.riyaazpal.icloud-sync-network")

    private static let hasShownInitialSyncHintKey = "hasShownInitialICloudSyncHint"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handleNetworkPathUpdate(path)
            }
        }
        networkMonitor.start(queue: networkMonitorQueue)
    }

    deinit {
        timelineSyncHintTask?.cancel()
        networkMonitor.cancel()
    }

    func showInitialTimelineSyncHintIfNeeded(duration: Duration = .seconds(8)) {
        guard RiyaazPalModelContainer.isICloudSyncEnabled else { return }
        guard !userDefaults.bool(forKey: Self.hasShownInitialSyncHintKey) else { return }
        guard isNetworkOnline else {
            shouldShowInitialHintWhenOnline = true
            return
        }

        userDefaults.set(true, forKey: Self.hasShownInitialSyncHintKey)
        showTimelineSyncHintForDuration(duration)
    }

    private var canShowSyncMessaging: Bool {
        RiyaazPalModelContainer.isICloudSyncEnabled && isNetworkOnline
    }

    private func showTimelineSyncHintForDuration(_ duration: Duration) {
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

    private func handleNetworkPathUpdate(_ path: NWPath) {
        let isOnline = path.status == .satisfied
        guard isNetworkOnline != isOnline else { return }

        isNetworkOnline = isOnline

        if !isOnline {
            timelineSyncHintTask?.cancel()
            isShowingTimelineSyncHint = false
        } else if shouldShowInitialHintWhenOnline {
            shouldShowInitialHintWhenOnline = false
            showInitialTimelineSyncHintIfNeeded()
            return
        }

        updateSyncingState()
    }

    private func updateSyncingState() {
        isSyncing = canShowSyncMessaging && isShowingTimelineSyncHint
    }
}
