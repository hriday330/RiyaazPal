//
//  GoalsPanel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-16.
//

import Foundation
import SwiftUI
import SwiftData

struct GoalsPanel: View {

    let goals: [GoalEntity]

    let onAddRaga: () -> Void
    let onAddTechnique: () -> Void
    let onEdit: () -> Void

    private var ragas: [GoalEntity] {
        goals.filter { $0.type == .raga }
    }

    private var techniques: [GoalEntity] {
        goals.filter { $0.type == .technique }
    }

    var body: some View {
        Group {
            if goals.isEmpty {
                emptyState
            } else {
                populatedState
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.08), radius: 10)
    }
}

private extension View {
    func insightCard(background: Color = Color("CardBackground")) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
    }
}

private extension GoalsPanel {

    // MARK: - Empty State

    var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Set your focus")
                .font(.headline)

            Text("Insights become more meaningful when you tell us what you're currently working on.")
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))

            HStack(spacing: 10) {
                Button(action: onAddRaga) {
                    Text("Add raga")
                }

                Button(action: onAddTechnique) {
                    Text("Add technique")
                }
            }
        }
    }

    // MARK: - Populated State

    var populatedState: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("Your current focus")
                    .font(.headline)

                Spacer()

                Button("Edit", action: onEdit)
                    .font(.subheadline)
            }

            if !ragas.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Raga")
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))

                    ForEach(ragas) { goal in
                        goalRow(goal)
                    }
                }
            }

            if !techniques.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Technique")
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))

                    ForEach(techniques) { goal in
                        goalRow(goal)
                    }
                }
            }
        }
    }

    // MARK: - Goal Row

    func goalRow(_ goal: GoalEntity) -> some View {
        HStack(alignment: .center) {

            Text("• \(goal.displayName)")
                .font(.subheadline)

            if let intent = goal.intent {
                Text("— \(intentLabel(intent))")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer()
        }
    }

    // MARK: - Intent Label

    func intentLabel(_ intent: GoalIntentRaw) -> String {
        switch intent {
        case .deepenExploration:
            return "deepen exploration"
        case .increaseComfort:
            return "increase comfort"
        case .stabilize:
            return "stabilize"
        case .improveClarity:
            return "improve clarity"
        case .increaseComplexity:
            return "increase complexity"
        case .buildStamina:
            return "build stamina"
        }
    }
}


#if DEBUG
import SwiftUI
import SwiftData

// MARK: - Empty

#Preview("GoalsPanel – Empty – Light") {
    let container = PreviewModelContainer.make()

    return NavigationStack {
        GoalsPanel(
            goals: [],
            onAddRaga: {},
            onAddTechnique: {},
            onEdit: {}
        )
        .padding()
    }
    .modelContainer(container)
    .preferredColorScheme(.light)
}

// MARK: - Raga

#Preview("GoalsPanel – Raga Focus") {
    let container = PreviewModelContainer.make()

    let goals = [
        GoalEntity(
            type: .raga,
            tagID: UUID(),
            displayName: "Yaman",
            intent: .increaseComfort
        )
    ]

    return NavigationStack {
        GoalsPanel(
            goals: goals,
            onAddRaga: {},
            onAddTechnique: {},
            onEdit: {}
        )
        .padding()
    }
    .modelContainer(container)
}

// MARK: - Technique

#Preview("GoalsPanel – Technique Focus") {
    let container = PreviewModelContainer.make()

    let goals = [
        GoalEntity(
            type: .technique,
            tagID: UUID(),
            displayName: "Layakari",
            intent: .stabilize
        ),
        GoalEntity(
            type: .technique,
            tagID: UUID(),
            displayName: "Meend",
            intent: .improveClarity
        )
    ]

    return NavigationStack {
        GoalsPanel(
            goals: goals,
            onAddRaga: {},
            onAddTechnique: {},
            onEdit: {}
        )
        .padding()
    }
    .modelContainer(container)
}

// MARK: - Mixed

#Preview("GoalsPanel – Mixed Focus – Dark") {
    let container = PreviewModelContainer.make()

    let goals = [
        GoalEntity(
            type: .raga,
            tagID: UUID(),
            displayName: "Marwa",
            intent: .deepenExploration
        ),
        GoalEntity(
            type: .raga,
            tagID: UUID(),
            displayName: "Yaman",
            intent: .deepenExploration
        ),
        GoalEntity(
            type: .technique,
            tagID: UUID(),
            displayName: "Layakari",
            intent: .stabilize
        )
    ]

    return NavigationStack {
        GoalsPanel(
            goals: goals,
            onAddRaga: {},
            onAddTechnique: {},
            onEdit: {}
        )
        .padding()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}

#endif
