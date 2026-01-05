//
//  EditSessionView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-02.
//

import Foundation
import SwiftUI

struct EditSessionView: View {
    @Environment(\.dismiss) private var dismiss

    private let session: PracticeSession
    @State private var draft: PracticeSessionDraft
    @State private var newTag: String = ""
    

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
                .padding(.top, 12)
                .padding(.horizontal)
                .background(Color("AppBackground"))

                VStack(spacing: 12) {
                    HStack {
                        Text("Started")
                        Spacer()
                        Text(formattedStartTime)
                    }

                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formattedDuration)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
                .padding(.horizontal)
                .padding(.top, 8)

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
                }
                .padding(.top, 16)

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
                .padding(.top, 8)
                
                detailedNotesInput

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
                .padding()
                .background(
                    Color("AppBackground")
                        
                )
            }
            .padding(.top, 30)
            .background(Color("AppBackground"))
        }
    }

    private func commit() {
        session.notes = draft.notes
        session.tags = draft.tags
        session.detailedNotes = draft.detailedNotes
    }
}

private extension EditSessionView {
    
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
        .padding(.top, 20)

    }

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: draft.startTime)
    }

    var formattedDuration: String {
        let totalSeconds = Int(draft.duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !draft.tags.contains(trimmed) else {
            newTag = ""
            return
        }

        draft.tags.append(trimmed)
        newTag = ""
    }
}

struct PracticeSessionDraft {
    let id: UUID
    let startTime: Date
    let duration: TimeInterval
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
        tags: []
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
        tags: []
    )

    context.insert(session)

    return EditSessionView(session: session)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
