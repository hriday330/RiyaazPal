//
//  PreviewModelContainer.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-03.
//

import Foundation

import SwiftData

@MainActor
enum PreviewModelContainer {
    static func make() -> ModelContainer {
        let container = try! ModelContainer(
            for:
                PracticeSession.self,
                GoalEntity.self,
                PracticeAreaEntity.self,
                PracticeAreaRatingEntity.self
            ,
            configurations: ModelConfiguration(
                isStoredInMemoryOnly: true
            )
        )
        return container
    }
}
