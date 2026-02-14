//
//  CategorySetupStepView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-25.
//

import Foundation
import SwiftUI
import SwiftData

struct CategorySetupStepView: View {

    let title: String
    let subtitle: String
    let category: TagCategoryModel
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {

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

            // using existing category detail editor
            CategoryDetailView(category: category)

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
    }
}

#Preview("Category Setup – Ragas") {
    let container = try! ModelContainer(
        for: TagCategoryModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let context = container.mainContext

    let ragaCategory = TagCategoryModel(
        name: "Raga",
        tags: ["yaman", "bhairav", "kafi"],
        isSystemDefault: true,
        order: 0,
        isFocusRelevant: true
    )

    context.insert(ragaCategory)

    return NavigationStack {
        CategorySetupStepView(
            title: "Your Ragas",
            subtitle: "Add the ragas you practice regularly.",
            category: ragaCategory,
            onContinue: {
                print("Continue tapped")
            },
            onSkip: {
                print("Skip tapped")
            }
        )
    }
    .modelContainer(container)
}

