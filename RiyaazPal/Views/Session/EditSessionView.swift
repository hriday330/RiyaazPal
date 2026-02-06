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
    @Environment(\.dismiss) private var dismiss

    private let session: PracticeSession
    @StateObject private var editSessionViewModel: EditSessionViewModel


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
                                text: $editSessionViewModel.draft.notes
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
                        EditSessionTagsSection(tags: $editSessionViewModel.draft.tags, newTag: $editSessionViewModel.newTag, onAddTag: editSessionViewModel.addTag)
                            .padding(.top, 16)
                        EditSessionNotesEditor(notes: $editSessionViewModel.draft.detailedNotes)
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
            .background(Color("AppBackground"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension EditSessionView {
    var saveAndCancelButtons: some View {
        VStack(spacing: 12) {
            Button {
                editSessionViewModel.commit()
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
