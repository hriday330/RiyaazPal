//
//  PracticeAreaQuestionnaireFlow.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-05-04.
//

import Foundation
import SwiftUI

struct PracticeAreaQuestionnaireFlow: View {

    let drafts: [PracticeAreaQuestionnaireDraft]
    let onScoreChanged: (UUID, Int) -> Void
    let onNotPracticed: (UUID) -> Void
    let onDone: () -> Void

    @State private var currentIndex = 0

    private var currentDraft: PracticeAreaQuestionnaireDraft? {
        guard drafts.indices.contains(currentIndex) else { return nil }
        return drafts[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                if drafts.isEmpty {
                    emptyState
                } else if let currentDraft {
                    questionContent(currentDraft)
                }
            }
            .navigationTitle("Reflect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDone)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private extension PracticeAreaQuestionnaireFlow {

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "slider.horizontal.3")
                .font(.largeTitle)
                .foregroundStyle(Color("AccentColor"))

            Text("No practice areas yet")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            Text("Add practice areas from Profile to reflect on them after each session.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("SecondaryText"))
                .padding(.horizontal, 28)
        }
    }

    func questionContent(_ draft: PracticeAreaQuestionnaireDraft) -> some View {
        VStack(spacing: 24) {
            progressText

            Spacer(minLength: 20)

            VStack(spacing: 18) {
                Text("How did \(draft.areaName) go for you today?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("PrimaryText"))
                    .padding(.horizontal)

                scorePanel(draft)
            }

            Spacer()

            navigationButtons
        }
        .padding()
    }

    var progressText: some View {
        Text("\(currentIndex + 1) of \(drafts.count)")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color("SecondaryText"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func scorePanel(_ draft: PracticeAreaQuestionnaireDraft) -> some View {
        VStack(spacing: 18) {
            HStack {
                Text(draft.didPractice ? "\(draft.resolvedScore)/10" : "Not practiced today")
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryText"))

                Spacer()
            }

            Slider(
                value: Binding(
                    get: { Double(draft.resolvedScore) },
                    set: { newValue in
                        onScoreChanged(draft.id, Int(newValue))
                    }
                ),
                in: 1...10,
                step: 1
            )
            .tint(Color("AccentColor"))

            Button {
                onNotPracticed(draft.id)
            } label: {
                HStack {
                    Image(systemName: draft.didPractice ? "circle" : "checkmark.circle.fill")
                    Text("I didn't work on this today")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(draft.didPractice ? Color("EditorBackground") : Color("AccentColor").opacity(0.16))
                )
                .foregroundStyle(draft.didPractice ? Color("PrimaryText") : Color("AccentColor"))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color("CardBackground"))
        )
        .shadow(color: .black.opacity(0.08), radius: 10)
    }

    var navigationButtons: some View {
        HStack(spacing: 12) {
            Button {
                currentIndex = max(0, currentIndex - 1)
            } label: {
                Text("Back")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color("EditorBackground"))
                    )
            }
            .disabled(currentIndex == 0)
            .foregroundStyle(currentIndex == 0 ? Color("SecondaryText") : Color("PrimaryText"))

            Button {
                if currentIndex == drafts.count - 1 {
                    onDone()
                } else {
                    currentIndex = min(drafts.count - 1, currentIndex + 1)
                }
            } label: {
                Text(currentIndex == drafts.count - 1 ? "Done" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color("AccentColor"))
                    )
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview("Questionnaire Flow") {
    PracticeAreaQuestionnaireFlow(
        drafts: [
            PracticeAreaQuestionnaireDraft(
                sessionID: UUID(),
                practiceAreaID: UUID(),
                areaName: "Sapat Taans",
                didPractice: false,
                score: nil
            ),
            PracticeAreaQuestionnaireDraft(
                sessionID: UUID(),
                practiceAreaID: UUID(),
                areaName: "Layakari",
                didPractice: true,
                score: 7
            )
        ],
        onScoreChanged: { _, _ in },
        onNotPracticed: { _ in },
        onDone: { }
    )
}
