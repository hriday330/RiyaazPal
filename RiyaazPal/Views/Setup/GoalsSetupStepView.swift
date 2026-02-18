//
//  GoalsSetupStepView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-18.
//

import Foundation
import SwiftUI
import SwiftData

struct GoalsSetupStepView: View {

    let title: String
    let subtitle: String
    let goals: [GoalEntity]

    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            // Header
            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // Embedded goals editor
            GoalsPanel(goals: goals)
                .padding(.horizontal)

            // CTA area
            VStack(spacing: 12) {
                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .font(.headline)

                Button("Skip for now") {
                    onSkip()
                }
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(Color("AppBackground").ignoresSafeArea())
    }
}

#Preview("Goals Setup – Empty") {
    let container = PreviewModelContainer.make()

    return NavigationStack {
        GoalsSetupPreviewHost()
    }
    .modelContainer(container)
}

#Preview("Goals Setup – With Focus") {
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

    context.insert(
        GoalEntity(
            type: .technique,
            categoryID: UUID(),
            tagName: "Layakari",
            intent: .stabilize
        )
    )

    return NavigationStack {
        GoalsSetupPreviewHost()
    }
    .modelContainer(container)
}

private struct GoalsSetupPreviewHost: View {

    @Query(filter: #Predicate<GoalEntity> { $0.isActive == true })
    private var activeGoals: [GoalEntity]

    var body: some View {
        GoalsSetupStepView(
            title: "Define your focus",
            subtitle: "Tell us what you're actively working on so Insights can coach your riyaaz.",
            goals: activeGoals,
            onContinue: {
                print("Continue tapped")
            },
            onSkip: {
                print("Skip tapped")
            }
        )
    }
}
