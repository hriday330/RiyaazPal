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
                TagCategoryModel.self,
                GoalEntity.self
            ,
            configurations: ModelConfiguration(
                isStoredInMemoryOnly: true
            )
        )

        let context = container.mainContext
        try! seedDefaultTagCategoriesIfNeeded(context: context)

        return container
    }
}

