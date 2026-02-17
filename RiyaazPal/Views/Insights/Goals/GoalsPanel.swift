//
//  GoalsPanel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-16.
//

import Foundation
import SwiftUI
import SwiftData

//
//  GoalsPanel.swift
//  RiyaazPal
//

import Foundation
import SwiftUI
import SwiftData

struct GoalsPanel: View {

    let goals: [GoalEntity]

    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = GoalsViewModel()

    @State private var isEditing: Bool = false

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
        .onAppear {
            viewModel.attachContext(context)
        }
//        .sheet(isPresented: $viewModel.isPresentingTagPicker) {
//            TagPickerView(
//                goalType: viewModel.pendingGoalType,
//                onSelect: viewModel.tagSelected
//            )
//        }
//        .sheet(isPresented: $viewModel.isPresentingIntentPicker) {
//            IntentPickerView(
//                onSelect: viewModel.intentSelected
//            )
//        }
        .alert("Focus limit reached", isPresented: $viewModel.showLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can keep up to 3 active goals at a time.")
        }
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
                Button("Add raga") {
                    viewModel.startAddFlow(type: .raga, currentGoals: goals)
                }

                Button("Add technique") {
                    viewModel.startAddFlow(type: .technique, currentGoals: goals)
                }
            }
        }
    }

    // MARK: - Populated State

    var populatedState: some View {
        VStack(alignment: .leading, spacing: 16) {

            header

            if !ragas.isEmpty || isEditing {
                section(
                    title: "Raga",
                    goals: ragas,
                    type: .raga
                )
            }

            if !techniques.isEmpty || isEditing {
                section(
                    title: "Technique",
                    goals: techniques,
                    type: .technique
                )
            }
        }
    }

    // MARK: - Header

    var header: some View {
        HStack {
            Text("Your current focus")
                .font(.headline)

            Spacer()

            Button(isEditing ? "Done" : "Edit") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditing.toggle()
                }
            }
            .font(.subheadline)
        }
    }

    // MARK: - Section

    func section(title: String, goals: [GoalEntity], type: GoalTypeRaw) -> some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))

            ForEach(goals) { goal in
                goalRow(goal)
            }

            if isEditing {
                Button {
                    viewModel.startAddFlow(type: type, currentGoals: self.goals)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("Add \(title.lowercased())")
                            .font(.caption)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Goal Row

    func goalRow(_ goal: GoalEntity) -> some View {
        HStack(alignment: .center) {

            Text("• \(goal.tagName)")
                .font(.subheadline)

            if let intent = goal.intent {
                Text("— \(intentLabel(intent))")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer()

            if isEditing {
                Button {
                    viewModel.removeGoal(goal)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
            }
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

// MARK: - Empty

#if DEBUG
import SwiftUI
import SwiftData

private struct GoalsPanelPreviewHost: View {
    @Query(filter: #Predicate<GoalEntity> { $0.isActive == true })
    private var activeGoals: [GoalEntity]

    var body: some View {
        GoalsPanel(goals: activeGoals)
            .padding()
    }
}
#endif


#Preview("GoalsPanel – Empty – Light") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    return NavigationStack {
        GoalsPanelPreviewHost()
    }
    .modelContainer(container)
    .preferredColorScheme(.light)
}

#Preview("GoalsPanel – Raga Focus") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    context.insert(
        GoalEntity(
            type: .raga,
            categoryID: UUID(),
            tagName: "Yaman",
            intent: .increaseComfort
        )
    )

    return NavigationStack {
        GoalsPanelPreviewHost()
    }
    .modelContainer(container)
}

#Preview("GoalsPanel – Technique Focus") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    context.insert(
        GoalEntity(
            type: .technique,
            categoryID: UUID(),
            tagName: "Layakari",
            intent: .stabilize
        )
    )
    context.insert(
        GoalEntity(
            type: .technique,
            categoryID: UUID(),
            tagName: "Meend",
            intent: .improveClarity
        )
    )

    return NavigationStack {
        GoalsPanelPreviewHost()
    }
    .modelContainer(container)
}

#Preview("GoalsPanel – Mixed Focus – Dark") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    context.insert(
        GoalEntity(
            type: .raga,
            categoryID: UUID(),
            tagName: "Marwa",
            intent: .deepenExploration
        )
    )
    context.insert(
        GoalEntity(
            type: .raga,
            categoryID: UUID(),
            tagName: "Yaman",
            intent: .deepenExploration
        )
    )
    context.insert(
        GoalEntity(
            type: .technique,
            categoryID: UUID(),
            tagName: "Layakari",
            intent: .stabilize
        )
    )

    return NavigationStack {
        GoalsPanelPreviewHost()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
