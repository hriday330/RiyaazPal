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

    static let schema = Schema([
        PracticeSession.self,
        GoalEntity.self,
        PracticeAreaEntity.self,
        PracticeAreaRatingEntity.self
    ])

    @MainActor
    static let shared: ModelContainer = {
        guard isICloudSyncEnabled else {
            return localContainer()
        }

        let cloudConfiguration = ModelConfiguration(
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
    }()

    static var isICloudSyncEnabled: Bool {
        UserDefaults.standard.object(forKey: iCloudSyncEnabledKey) as? Bool ?? true
    }

    private static func localContainer() -> ModelContainer {
        let localConfiguration = ModelConfiguration(schema: schema)
        return try! ModelContainer(
            for: schema,
            configurations: [localConfiguration]
        )
    }
}
