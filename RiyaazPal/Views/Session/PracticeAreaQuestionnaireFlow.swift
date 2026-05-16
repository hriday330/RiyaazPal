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
    let sessionType: SessionType
    let onScoreChanged: (UUID, Int) -> Void
    let onNotPracticed: (UUID) -> Void
    let onAddPracticeArea: (String) -> PracticeAreaInlineAddResult
    let canRepeatPreviousReflection: Bool
    let onRepeatPreviousReflection: () -> Void
    let onDone: () -> Void

    @State private var currentIndex = 0
    @State private var showingAddPracticeArea = false

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
            .sheet(isPresented: $showingAddPracticeArea) {
                InlinePracticeAreaAddSheet(
                    onAddPracticeArea: onAddPracticeArea
                )
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: drafts.count) { _, newCount in
                guard newCount > 0 else {
                    currentIndex = 0
                    return
                }

                currentIndex = min(currentIndex, newCount - 1)
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

            Text(emptyStateMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("SecondaryText"))
                .padding(.horizontal, 28)

            Button {
                showingAddPracticeArea = true
            } label: {
                Label("Add Practice Area", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("AccentColor"))
            .padding(.top, 4)
        }
    }

    func questionContent(_ draft: PracticeAreaQuestionnaireDraft) -> some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                progressText

                Button {
                    showingAddPracticeArea = true
                } label: {
                    Label("Add Practice Area", systemImage: "plus.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .labelStyle(.titleAndIcon)
                }
                .foregroundStyle(Color("AccentColor"))
            }

            if canRepeatPreviousReflection {
                repeatPreviousReflectionButton
            }

            Spacer(minLength: 20)

            VStack(spacing: 18) {
                Text(questionText(for: draft))
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

    var repeatPreviousReflectionButton: some View {
        Button(action: onRepeatPreviousReflection) {
            Label("Repeat last reflection", systemImage: "arrow.uturn.backward.circle.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color("AccentColor").opacity(0.14))
                )
                .foregroundStyle(Color("AccentColor"))
        }
        .buttonStyle(.plain)
    }

    func scorePanel(_ draft: PracticeAreaQuestionnaireDraft) -> some View {
        VStack(spacing: 18) {
            HStack {
                Text(draft.didPractice ? "\(draft.resolvedScore)/10" : inactiveScoreText)
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
                    Text(inactiveButtonText)
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

    var emptyStateMessage: String {
        switch sessionType {
        case .practice:
            return "Add practice areas to reflect on them after each session."
        case .concert:
            return "Add practice areas to reflect on them after each concert."
        }
    }

    var inactiveScoreText: String {
        switch sessionType {
        case .practice:
            return "Not practiced today"
        case .concert:
            return "Not performed today"
        }
    }

    var inactiveButtonText: String {
        switch sessionType {
        case .practice:
            return "I didn't work on this today"
        case .concert:
            return "I didn't perform this today"
        }
    }

    func questionText(for draft: PracticeAreaQuestionnaireDraft) -> String {
        switch sessionType {
        case .practice:
            return "How did \(draft.areaName) go for you today?"
        case .concert:
            return "How did \(draft.areaName) go in performance?"
        }
    }
}

enum PracticeAreaInlineAddResult {
    case added
    case duplicate
    case emptyName
    case failed
}

private struct InlinePracticeAreaAddSheet: View {
    let onAddPracticeArea: (String) -> PracticeAreaInlineAddResult

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var message: String?
    @FocusState private var isFocused

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Add Practice Area")
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryText"))

                TextField("Add practice area", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onSubmit(addPracticeArea)

                if let message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }

                Button(action: addPracticeArea) {
                    Label("Add Practice Area", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentColor"))
                .disabled(trimmedName.isEmpty)

                Spacer(minLength: 0)
            }
            .padding()
            .background(Color("AppBackground"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    private func addPracticeArea() {
        switch onAddPracticeArea(trimmedName) {
        case .added:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        case .duplicate:
            message = "That practice area already exists."
        case .emptyName:
            message = "Enter a practice area name."
        case .failed:
            message = "Could not add this practice area."
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
        sessionType: .practice,
        onScoreChanged: { _, _ in },
        onNotPracticed: { _ in },
        onAddPracticeArea: { _ in .added },
        canRepeatPreviousReflection: true,
        onRepeatPreviousReflection: { },
        onDone: { }
    )
}

#Preview("Concert Questionnaire Flow") {
    PracticeAreaQuestionnaireFlow(
        drafts: [
            PracticeAreaQuestionnaireDraft(
                sessionID: UUID(),
                practiceAreaID: UUID(),
                areaName: "Bol Taans",
                didPractice: false,
                score: nil
            )
        ],
        sessionType: .concert,
        onScoreChanged: { _, _ in },
        onNotPracticed: { _ in },
        onAddPracticeArea: { _ in .added },
        canRepeatPreviousReflection: false,
        onRepeatPreviousReflection: { },
        onDone: { }
    )
}
