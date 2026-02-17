//
//  GoalsViewModel.swift
//  RiyaazPal
//

import Foundation
import SwiftUI
import SwiftData

final class GoalsViewModel: ObservableObject {

    private let maxActiveGoals = 3

    // MARK: - UI Flow State

    @Published var isPresentingTagPicker = false
    @Published var isPresentingIntentPicker = false

    @Published var pendingGoalType: GoalTypeRaw?
    @Published var selectedCategory: TagCategoryModel?
    @Published var selectedTagName: String?
    @Published var selectedIntent: GoalIntentRaw?

    @Published var showLimitAlert = false

    // MARK: - Dependencies

    private var context: ModelContext?

    func attachContext(_ context: ModelContext) {
        self.context = context
    }

    // MARK: - Flow Control

    @MainActor
    func startAddFlow(type: GoalTypeRaw, currentGoals: [GoalEntity]) {
        guard currentGoals.count < maxActiveGoals else {
            showLimitAlert = true
            return
        }

        pendingGoalType = type
        selectedCategory = nil
        selectedTagName = nil
        selectedIntent = nil

        isPresentingTagPicker = true
    }

    /// Called when a tag is picked from TagPickerView
    @MainActor
    func tagSelected(category: TagCategoryModel, tagName: String) {
        selectedCategory = category
        selectedTagName = tagName

        isPresentingTagPicker = false
        isPresentingIntentPicker = true
    }

    @MainActor
    func intentSelected(_ intent: GoalIntentRaw?) {
        selectedIntent = intent
        isPresentingIntentPicker = false

        createGoal()
    }

    // MARK: - Goal Lifecycle

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

    // MARK: - Creation

    @MainActor
    private func createGoal() {
        guard
            let context,
            let category = selectedCategory,
            let tagName = selectedTagName,
            let type = pendingGoalType
        else { return }

        let newGoal = GoalEntity(
            type: type,
            categoryID: category.id,
            tagName: tagName,
            intent: selectedIntent
        )

        context.insert(newGoal)

        do {
            try context.save()
        } catch {
            print("GoalsViewModel.createGoal error:", error)
        }

        resetFlow()
    }

    // MARK: - Reset

    @MainActor
    private func resetFlow() {
        pendingGoalType = nil
        selectedCategory = nil
        selectedTagName = nil
        selectedIntent = nil

        isPresentingTagPicker = false
        isPresentingIntentPicker = false
    }
}
