//
//  RiyaazPalModelContainer.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-16.
//

import SwiftData

enum RiyaazPalModelContainer {
    static let cloudKitContainerIdentifier = "iCloud.com.hridaybuddhdev.RiyaazPal"

    static let schema = Schema([
        PracticeSession.self,
        GoalEntity.self,
        PracticeAreaEntity.self,
        PracticeAreaRatingEntity.self
    ])

    @MainActor
    static let shared: ModelContainer = {
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

            let localConfiguration = ModelConfiguration(schema: schema)
            return try! ModelContainer(
                for: schema,
                configurations: [localConfiguration]
            )
        }
    }()
}
