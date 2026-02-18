//
//  SetupView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-23.
//

import Foundation
import SwiftUI
import SwiftData

enum SetupStep: Int, CaseIterable {
    case welcome
    case goals
    case ragas
    case talas
    case sections
    case tempos
    case techniques
    case done

    func next() -> SetupStep? {
        SetupStep(rawValue: rawValue + 1)
    }
}


struct SetupView: View {

    @State private var step: SetupStep = .welcome
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false

    @Query(sort: \TagCategoryModel.order)
    private var categories: [TagCategoryModel]
    
    @Query(filter: #Predicate<GoalEntity> { $0.isActive == true })
    private var activeGoals: [GoalEntity]

    var body: some View {
        NavigationStack {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            SetupWelcomeView {
                advance()
            }
        
        case .goals:
            GoalsSetupStepView(
                title: "Define your focus",
                subtitle: "Tell us what your current goals are musically",
                goals: activeGoals,
                onContinue: advance,
                onSkip: advance
            )
            
        
        case .ragas:
            if let category = getCategory(named: "Raga") {
                CategorySetupStepView(
                    title: "Your Ragas",
                    subtitle: "Add the ragas you practice regularly.",
                    category: category,
                    onContinue: advance,
                    onSkip: advance
                )
            }

        case .talas:
            if let category = getCategory(named: "Taal") {
                CategorySetupStepView(
                    title: "Your Talas",
                    subtitle: "Which rhythmic cycles do you use?",
                    category: category,
                    onContinue: advance,
                    onSkip: advance
                )
            }
        case .sections:
            if let category = getCategory(named: "Section") {
                CategorySetupStepView(
                    title: "Practice Sections",
                    subtitle: "Alap, jor, jhala, gat…",
                    category: category,
                    onContinue: advance,
                    onSkip: advance
                )
            }

        case .tempos:
            if let category = getCategory(named: "Tempo") {
                CategorySetupStepView(
                    title: "Tempos",
                    subtitle: "Vilambit, madhya, drut.",
                    category: category,
                    onContinue: advance,
                    onSkip: advance
                )
            }

        case .techniques:
            if let category = getCategory(named: "Technique") {
                CategorySetupStepView(
                    title: "Techniques",
                    subtitle: "Meend, gamak, kan, bol patterns.",
                    category: category,
                    onContinue: advance,
                    onSkip: advance
                )
            }

        case .done:
            SetupCompleteView {
                hasCompletedSetup = true
            }
        }
    }

    private func getCategory(named name: String) -> TagCategoryModel? {
        return categories.first { $0.name == name }
    }

    private func advance() {
        step = step.next() ?? .done
    }
}


#Preview("Setup Flow") {
    let container = try! ModelContainer(
        for: TagCategoryModel.self, GoalEntity.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let context = container.mainContext

    context.insert(
        TagCategoryModel(
            name: "Raga",
            tags: ["yaman", "bhairav", "kafi"],
            isSystemDefault: true,
            order: 0,
            isFocusRelevant: true
        )
    )

    context.insert(
        TagCategoryModel(
            name: "Taal",
            tags: ["teentaal", "jhaptaal"],
            isSystemDefault: true,
            order: 1,
            isFocusRelevant: true
        )
    )

    context.insert(
        TagCategoryModel(
            name: "Section",
            tags: ["alap", "jor", "jhala", "gat"],
            isSystemDefault: true,
            order: 2,
            isFocusRelevant: true
        )
    )

    context.insert(
        TagCategoryModel(
            name: "Tempo",
            tags: ["vilambit", "madhya", "drut"],
            isSystemDefault: true,
            order: 3,
            isFocusRelevant: true
        )
    )

    context.insert(
        TagCategoryModel(
            name: "Technique",
            tags: ["meend", "gamak", "kan"],
            isSystemDefault: true,
            order: 4,
            isFocusRelevant: true
        )
    )

    return NavigationStack {
        SetupView()
    }
    .modelContainer(container)
}
