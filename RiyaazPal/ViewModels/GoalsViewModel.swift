//
//  GoalsViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-17.
//

import Foundation
import SwiftUI
import SwiftData

final class GoalsViewModel: ObservableObject {

    private let maxActiveGoals = 3

    @Published var showLimitAlert = false
    
    @Published var showDuplicateAlert = false

    private var context: ModelContext?

    func attachContext(_ context: ModelContext) {
        self.context = context
    }

    @MainActor
    func createGoal(
        type: GoalTypeRaw,
        category: TagCategoryModel,
        tagName: String,
        intent: GoalIntentRaw?,
        currentGoals: [GoalEntity]
    ) -> Bool {

        guard let context else { return false }

        let activeGoals = currentGoals.filter { $0.isActive }

        // enforce max goals
        guard activeGoals.count < maxActiveGoals else {
            showLimitAlert = true
            return false
        }

        // prevent duplicates
        let alreadyExists = activeGoals.contains {
            $0.tagName.caseInsensitiveCompare(tagName) == .orderedSame && $0.type == type
        }

        guard !alreadyExists else {
            showDuplicateAlert = true
            return false
        }

        let newGoal = GoalEntity(
            type: type,
            categoryID: category.id,
            tagName: tagName,
            intent: intent
        )

        context.insert(newGoal)

        do {
            try context.save()
            return true
        } catch {
            print("GoalsViewModel.createGoal error:", error)
            return false
        }
    }


    // MARK: - Deletion

    @MainActor
    func removeGoal(_ goal: GoalEntity) {
        guard let context else { return }

        goal.isActive = false

        do {
            try context.save()
        } catch {
            print("GoalsViewModel.removeGoal error:", error)
        }
    }
}

