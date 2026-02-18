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

    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = GoalsViewModel()

    @State private var isEditing: Bool = false

    @State private var isAddingGoal: Bool = false
    @State private var addingType: GoalTypeRaw = .raga
    @State private var selectedTagName: String?
    @State private var selectedIntent: GoalIntentRaw = .increaseComfort
    @State private var showIntentSelector = false
    @State private var showInlineDuplicateMessage = false

    @Query(sort: \TagCategoryModel.order)
    private var categories: [TagCategoryModel]

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
        .alert("Focus limit reached", isPresented: $viewModel.showLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can keep up to 3 active goals at a time.")
        }.onChange(of: viewModel.showDuplicateAlert) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showInlineDuplicateMessage = true
                }

                // auto-hide after short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showInlineDuplicateMessage = false
                    }
                }

                viewModel.showDuplicateAlert = false
            }
        }

    }
}

// MARK: - Card Styling

private extension View {
    func insightCard(background: Color = Color("CardBackground")) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(background)
            )
    }
}

// MARK: - Empty State

private extension GoalsPanel {

    var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Set your focus")
                .font(.headline)

            Text("Insights become more meaningful when you tell us what you're currently working on.")
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))

            if isAddingGoal {
                inlineCreator
            } else {
                Button("Add focus") {
                    isAddingGoal = true
                }
            }
        }
    }
}

// MARK: - Populated State

private extension GoalsPanel {

    var populatedState: some View {
        VStack(alignment: .leading, spacing: 16) {

            header

            if !ragas.isEmpty || isEditing {
                section(title: "Raga", goals: ragas)
            }

            if !techniques.isEmpty || isEditing {
                section(title: "Technique", goals: techniques)
            }
            
            if isAddingGoal {
                inlineCreator
            }
        }
    }
}

// MARK: - Header

private extension GoalsPanel {

    var header: some View {
        HStack {
            Text("Your current focus")
                .font(.headline)

            Spacer()

            Button(isEditing ? "Done" : "Edit") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if (isEditing) {
                        saveGoal()
                    } else {
                        isEditing.toggle()
                    }
                    
                }
            }
            .font(.subheadline)
        }
    }
}

// MARK: - Sections

private extension GoalsPanel {

    func section(title: String, goals: [GoalEntity]) -> some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))

            ForEach(goals) { goal in
                goalRow(goal)
            }

            if isEditing {
                Button {
                    addingType = (title == "Raga") ? .raga : .technique
                    isAddingGoal = true
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
}

// MARK: - Inline Goal Creator

private extension GoalsPanel {

    var inlineCreator: some View {
        VStack(alignment: .leading, spacing: 10) {

            Picker("Type", selection: $addingType) {
                Text("Raga").tag(GoalTypeRaw.raga)
                Text("Technique").tag(GoalTypeRaw.technique)
            }
            .pickerStyle(.segmented)

            Picker("Select", selection: $selectedTagName) {
                Text("Select...").tag(String?.none)

                ForEach(tagOptions(), id: \.self) { tag in
                    Text(tag).tag(Optional(tag))
                }
            }

            if showIntentSelector {
                Picker("Intent", selection: $selectedIntent) {
                    Text("Increase comfort").tag(GoalIntentRaw.increaseComfort)
                    Text("Deepen exploration").tag(GoalIntentRaw.deepenExploration)
                    Text("Stabilize").tag(GoalIntentRaw.stabilize)
                    Text("Improve clarity").tag(GoalIntentRaw.improveClarity)
                    Text("Increase complexity").tag(GoalIntentRaw.increaseComplexity)
                    Text("Build stamina").tag(GoalIntentRaw.buildStamina)
                }
            } else {
                Button("Add intent (optional)") {
                    showIntentSelector = true
                }
                .font(.caption)
            }

            Button("Save") {
                saveGoal()
            }
            .disabled(selectedTagName == nil)
            
            if showInlineDuplicateMessage {
                Text("This focus is already in your goals.")
                    .font(.caption)
                    .foregroundStyle(Color.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
                    }
        .padding(.top, 6)
    }
}

// MARK: - Goal Row

private extension GoalsPanel {

    func goalRow(_ goal: GoalEntity) -> some View {
        HStack {

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
}

// MARK: - Tag Options

private extension GoalsPanel {

    func tagOptions() -> [String] {
        categories
            .filter { addingType == .raga ? $0.name == "Raga" : $0.name == "Technique" }
            .flatMap { $0.tags }
            .sorted()
    }
}

// MARK: - Save Goal

private extension GoalsPanel {

    func saveGoal() {
        guard
            let tagName = selectedTagName,
            let category = categories.first(where: { $0.tags.contains(tagName) })
        else { return }

        var res = viewModel.createGoal(
            type: addingType,
            category: category,
            tagName: tagName,
            intent: selectedIntent,
            currentGoals: goals
        )

        if (res) {
            withAnimation {
                isAddingGoal = false
                isEditing = false
                selectedTagName = nil
                selectedIntent = .increaseComfort
                showIntentSelector = false
            }
        }
    }
}

// MARK: - Intent Labels

private extension GoalsPanel {

    func intentLabel(_ intent: GoalIntentRaw) -> String {
        switch intent {
        case .deepenExploration: return "deepen exploration"
        case .increaseComfort: return "increase comfort"
        case .stabilize: return "stabilize"
        case .improveClarity: return "improve clarity"
        case .increaseComplexity: return "increase complexity"
        case .buildStamina: return "build stamina"
        }
    }
}

#if DEBUG
// MARK: - Preview Host

private struct GoalsPanelPreviewHost: View {

    @Query(filter: #Predicate<GoalEntity> { $0.isActive == true })
    private var activeGoals: [GoalEntity]

    var body: some View {
        GoalsPanel(goals: activeGoals)
            .padding()
    }
}

// MARK: - Previews

#Preview("GoalsPanel – Empty – Light") {
    let container = PreviewModelContainer.make()

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
#endif
