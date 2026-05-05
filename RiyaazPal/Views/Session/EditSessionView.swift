//
// EditSessionView.swift
// RiyaazPal
//
// Created by Hriday Buddhdev on 2026-01-02.
//

import Foundation
import SwiftUI
import SwiftData 

struct EditSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let session: PracticeSession
    @StateObject private var editSessionViewModel: EditSessionViewModel
    @StateObject private var practiceAreasViewModel = PracticeAreasViewModel()
    
    @Query(sort: \TagCategoryModel.order)
    private var categories: [TagCategoryModel]

    @Query(sort: \PracticeAreaEntity.order)
    private var practiceAreas: [PracticeAreaEntity]

    @Query(sort: \PracticeAreaRatingEntity.createdAt)
    private var practiceAreaRatings: [PracticeAreaRatingEntity]

    @State private var showPracticeAreaQuestionnaire = false

    init(session: PracticeSession) {
        self.session = session
        _editSessionViewModel = StateObject(
            wrappedValue: EditSessionViewModel(session: session)
        )
    }
    


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                ScrollView {
                    VStack(spacing: 8) {
                    
                        VStack(spacing: 8) {
                            TextField(
                                "Practice Session",
                                text: Binding(
                                    get: { editSessionViewModel.draft.notes },
                                    set: { editSessionViewModel.updateNotes($0) }
                                )
                            )
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("PrimaryText"))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .submitLabel(.done)

                            Divider()
                        }
                        .padding(.top, 20)
                        .padding(.horizontal)
                        VStack(spacing: 12) {
                            startDateTimePicker
                            durationStepper

                        }
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                        .padding(.horizontal)
                        .padding(.top, 8)
                        SessionTypePicker(sessionType: $editSessionViewModel.draft.sessionType)
                            .padding(.horizontal)
                            .padding(.top, 16)
                        if editSessionViewModel.draft.sessionType == .concert {
                            confidenceSection
                                .padding(.horizontal)
                                .padding(.top, 16)
                        }
                        EditSessionTagsSection(tags: $editSessionViewModel.draft.tags, newTag: $editSessionViewModel.newTag, onAddTag: editSessionViewModel.addTag)
                            .padding(.top, 16)
                        if !editSessionViewModel.suggestedTags.isEmpty {
                            TagSuggestionsSection(
                                suggestions: editSessionViewModel.suggestedTags,
                                onTap: { tag in
                                    editSessionViewModel.addSuggestedTag(tag)
                                }
                            )
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        reflectOnSessionButton
                            .padding(.horizontal)
                            .padding(.top, 20)

                        EditSessionNotesEditor(
                            notes: Binding(
                                get: { editSessionViewModel.draft.detailedNotes },
                                set: { editSessionViewModel.updateDetailedNotes($0) }
                            )
                        )
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                saveAndCancelButtons
                    .padding()
                    .background(
                        Color("AppBackground")
                            .shadow(.drop(radius: 1, y: -1))
                    )
            }
            .onAppear {
                practiceAreasViewModel.attachContext(context)
                editSessionViewModel.configureTagSource(categories: categories)
                editSessionViewModel.configurePracticeAreaQuestionnaire(
                    practiceAreas: practiceAreas,
                    existingRatings: sessionPracticeAreaRatings
                )
            }
            .background(Color("AppBackground"))
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showPracticeAreaQuestionnaire) {
                PracticeAreaQuestionnaireFlow(
                    drafts: editSessionViewModel.practiceAreaDrafts,
                    sessionType: editSessionViewModel.draft.sessionType,
                    onScoreChanged: { draftID, score in
                        editSessionViewModel.updatePracticeAreaScore(
                            for: draftID,
                            score: score
                        )
                    },
                    onNotPracticed: { draftID in
                        editSessionViewModel.markPracticeAreaNotPracticed(
                            draftID: draftID
                        )
                    },
                    onAddPracticeArea: { name in
                        addPracticeAreaFromQuestionnaire(name)
                    },
                    onDone: {
                        showPracticeAreaQuestionnaire = false
                    }
                )
                .onAppear {
                    editSessionViewModel.markPracticeAreaReflectionStarted()
                }
            }
        }
    }
}

private extension EditSessionView {
    var sessionPracticeAreaRatings: [PracticeAreaRatingEntity] {
        practiceAreaRatings.filter { $0.sessionID == session.id }
    }

    func addPracticeAreaFromQuestionnaire(_ name: String) -> PracticeAreaInlineAddResult {
        practiceAreasViewModel.showDuplicateAlert = false
        practiceAreasViewModel.showEmptyNameAlert = false

        guard let createdArea = practiceAreasViewModel.createArea(
            name: name,
            currentAreas: practiceAreas
        ) else {
            if practiceAreasViewModel.showEmptyNameAlert {
                practiceAreasViewModel.showEmptyNameAlert = false
                return .emptyName
            }

            if practiceAreasViewModel.showDuplicateAlert {
                practiceAreasViewModel.showDuplicateAlert = false
                return .duplicate
            }

            return .failed
        }

        editSessionViewModel.appendPracticeAreaDraft(for: createdArea)
        return .added
    }

    var saveAndCancelButtons: some View {
        VStack(spacing: 12) {
            Button {
                editSessionViewModel.commit()
                editSessionViewModel.commitPracticeAreaRatings(
                    context: context,
                    existingRatings: sessionPracticeAreaRatings
                )
                try? context.save()
                dismiss()
            } label: {
                Text("Save Changes")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color("AccentColor"))
                    )
                    .foregroundStyle(.white)
            }

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
            }
        }
    }

    var reflectOnSessionButton: some View {
        Button {
            showPracticeAreaQuestionnaire = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    Text(reflectionButtonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("PrimaryText"))

                    Text(reflectionStatusText)
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("EditorBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("EditorBorder"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    var reflectionStatusText: String {
        guard !editSessionViewModel.practiceAreaDrafts.isEmpty else {
            return "Add practice areas to reflect"
        }

        guard editSessionViewModel.hasPracticeAreaReflection else {
            return "Not started"
        }

        let practicedCount = editSessionViewModel.practicedAreaCount

        if practicedCount == 0 {
            return editSessionViewModel.draft.sessionType == .concert
                ? "All areas marked not performed"
                : "All areas marked not practiced"
        }

        let verb = editSessionViewModel.draft.sessionType == .concert
            ? "performed"
            : "practiced"

        return "\(practicedCount) of \(editSessionViewModel.practiceAreaDrafts.count) areas \(verb)"
    }

    var reflectionButtonTitle: String {
        editSessionViewModel.draft.sessionType == .concert
            ? "Reflect on Concert"
            : "Reflect on Session"
    }
    
    var startDateTimePicker: some View {
        Button {
            editSessionViewModel.showingStartTimePicker = true
        } label: {
            HStack {
                Text("Started")
                    .foregroundStyle(Color("SecondaryText"))

                Spacer()

                Text(formattedStartTime)
                    .foregroundStyle(Color("PrimaryText"))

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("EditorBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("EditorBorder"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $editSessionViewModel.showingStartTimePicker) {
            DateTimePickerSheet(
                startTime: $editSessionViewModel.draft.startTime
            )
        }

    }

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: editSessionViewModel.draft.startTime)
    }

    private var durationMinutes: Int {
        get { Int(editSessionViewModel.draft.duration / 60) }
        set { editSessionViewModel.draft.duration = TimeInterval(newValue * 60) }
    }

    private var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60

        if hours > 0 {
            return minutes > 0
                ? "\(hours) hr \(minutes) min"
                : "\(hours) hr"
        } else {
            return "\(minutes) min"
        }
    }
    
    var durationStepper: some View {
        Button {
            editSessionViewModel.showingDurationPicker = true
        } label: {
            HStack {
                Text("Duration")
                    .foregroundStyle(Color("SecondaryText"))

                Spacer()

                Text(formattedDuration)
                    .foregroundStyle(Color("PrimaryText"))

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("EditorBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("EditorBorder"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $editSessionViewModel.showingDurationPicker) {
            DurationPickerSheet(
                duration: $editSessionViewModel.draft.duration
            )
        }


    }
}

private extension EditSessionView {
    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("Performance Confidence")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color("PrimaryText"))

                Spacer()

                Text("\(editSessionViewModel.draft.resolvedConfidence)/10")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Slider(
                value: Binding(
                    get: { Double(editSessionViewModel.draft.resolvedConfidence) },
                    set: { editSessionViewModel.draft.resolvedConfidence = Int($0) }
                ),
                in: 1...10,
                step: 1
            )
            .tint(Color("AccentColor"))

            Text(confidenceLabel)
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("EditorBackground"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("EditorBorder"), lineWidth: 1)
        )
    }
    
    private var confidenceLabel: String {
        switch editSessionViewModel.draft.resolvedConfidence {
        case 1...3:
            return "Low confidence"
        case 4...6:
            return "Moderate confidence"
        case 7...8:
            return "Strong confidence"
        case 9...10:
            return "Very confident"
        default:
            return ""
        }
    }
}
#Preview("Edit Session – Light") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    let session = PracticeSession(
        startTime: Date(),
        duration: 900,
        notes: "Alap practice focusing on slow meend and tone clarity.",
        tags: ["Raga Yaman", "Alap"]
    )

    context.insert(session)

    return EditSessionView(session: session)
        .modelContainer(container)
        .preferredColorScheme(.light)
}

#Preview("Edit Session – Dark") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    let session = PracticeSession(
        startTime: Date(),
        duration: 900,
        notes: "Alap practice focusing on slow meend and tone clarity.",
        tags: ["Raga Yaman", "Alap", "Technique", "Tarana", "Sargam"]
    )

    context.insert(session)

    return EditSessionView(session: session)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
