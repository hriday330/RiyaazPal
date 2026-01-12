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
    @State private var draft: PracticeSessionDraft
    @State private var newTag: String = ""
    
    @State private var showingDurationPicker = false
    @State private var showingStartTimePicker = false


    init(session: PracticeSession) {
        self.session = session
        _draft = State(
            initialValue: PracticeSessionDraft(
                id: session.id,
                startTime: session.startTime,
                duration: session.duration,
                notes: session.notes,
                tags: session.tags,
                detailedNotes: session.detailedNotes
            )
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
                                text: $draft.notes
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
                        tagsSection
                            .padding(.top, 16)
                        detailedNotesInput
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

    private func commit() {
        session.notes = draft.notes
        session.tags = draft.tags
        session.detailedNotes = draft.detailedNotes
        session.duration = draft.duration
        session.startTime = draft.startTime
    }
}

private extension EditSessionView {
    
    var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tags")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))
                .padding(.horizontal)

            FlowLayout(spacing: 8) {
                ForEach(draft.tags, id: \.self) { tag in
                    TagChip(
                        tag: tag,
                        onDelete: {
                            draft.tags.removeAll { $0 == tag }
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 8) {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit(addTag)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("EditorBorder"), lineWidth: 1)
                    )

                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color("AccentColor"))
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
        }
    }

    var detailedNotesInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))
                .padding(.horizontal)
            
            ZStack(alignment: .topLeading) {
                if draft.detailedNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("What felt good? What needs work?")
                        .foregroundStyle(Color("SecondaryText"))
                        .padding(.top, 20)
                        .padding(.leading, 18)
                }

                TextEditor(text: $draft.detailedNotes)
                    .font(.body)
                    .foregroundStyle(Color("PrimaryText"))
                    .scrollContentBackground(.hidden)
                    .padding(12)
            }
            .frame(minHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("EditorBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("EditorBorder"), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
    
    var saveAndCancelButtons: some View {
        VStack(spacing: 12) {
            Button {
                commit()
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
            showingStartTimePicker = true
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
        .sheet(isPresented: $showingStartTimePicker) {
            DateTimePickerSheet(
                startTime: $draft.startTime
            )
        }

    }

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: draft.startTime)
    }

    private var durationMinutes: Int {
        get { Int(draft.duration / 60) }
        set { draft.duration = TimeInterval(newValue * 60) }
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
            showingDurationPicker = true
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
        .sheet(isPresented: $showingDurationPicker) {
            DurationPickerSheet(
                duration: $draft.duration
            )
        }


    }

    func addTag() {
        let normalized = normalizeTag(newTag)
        guard !normalized.isEmpty else { return }
        let existing = draft.tags
                .map(normalizeTag)
                .contains(normalized)
        guard !existing else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }
        
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)

        draft.tags.append(trimmed)
        newTag = ""
    }
    
    func normalizeTag(_ tag: String) -> String {
        tag
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    
   
}

struct PracticeSessionDraft {
    let id: UUID
    var startTime: Date
    var duration: TimeInterval
    var notes: String
    var tags: [String]
    var detailedNotes: String
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
