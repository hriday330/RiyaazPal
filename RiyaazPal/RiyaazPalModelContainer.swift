//
//  RiyaazPalModelContainer.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-16.
//

import Foundation
import SwiftData

enum RiyaazPalModelContainer {
    static let cloudKitContainerIdentifier = "iCloud.com.hridaybuddhdev.RiyaazPal"
    static let iCloudSyncEnabledKey = "iCloudSyncEnabled"
    static let hasCompletedSetupKey = "hasCompletedSetup"
    private static let cloudStoreName = "RiyaazPalCloud"
    private static let localStoreName = "RiyaazPalLocal"

    static let schema = Schema([
        PracticeSession.self,
        GoalEntity.self,
        PracticeAreaEntity.self,
        PracticeAreaRatingEntity.self
    ])

    @MainActor
    static func makeForLaunch() -> ModelContainer {
        guard UserDefaults.standard.bool(forKey: hasCompletedSetupKey) else {
            return inMemoryContainer()
        }

        return makeFromStoredPreference()
    }

    @MainActor
    static func makeFromStoredPreference() -> ModelContainer {
        make(isICloudSyncEnabled: storedICloudSyncPreference)
    }

    @MainActor
    static func make(isICloudSyncEnabled: Bool) -> ModelContainer {
        guard isICloudSyncEnabled else {
            return localContainer()
        }

        let cloudConfiguration = ModelConfiguration(
            cloudStoreName,
            schema: schema,
            cloudKitDatabase: .private(cloudKitContainerIdentifier)
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [cloudConfiguration]
            )
        } catch {
            assertionFailure("Failed to create iCloud SwiftData container: \(error)")

            return localContainer()
        }
    }

    private static var storedICloudSyncPreference: Bool {
        let defaults = UserDefaults.standard
        if let storedPreference = defaults.object(forKey: iCloudSyncEnabledKey) as? Bool {
            return storedPreference
        }

        return defaults.bool(forKey: hasCompletedSetupKey)
    }

    private static func localContainer() -> ModelContainer {
        let localConfiguration = ModelConfiguration(
            localStoreName,
            schema: schema
        )
        return try! ModelContainer(
            for: schema,
            configurations: [localConfiguration]
        )
    }

    private static func inMemoryContainer() -> ModelContainer {
        let inMemoryConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try! ModelContainer(
            for: schema,
            configurations: [inMemoryConfiguration]
        )
    }
}
