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
    
    @State private var draft: PracticeSession
    @State private var newTag: String = ""

    let onSave: (PracticeSession) -> Void
    
    init(session: PracticeSession, onSave: @escaping (PracticeSession) -> Void) {
        _draft = State(initialValue: session)
        self.onSave = onSave
    }
    
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
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
                    .onSubmit {
                        // dismiss keyboard on return
                    }

                    Divider()
                }
                .padding(.top, 12)
                .padding(.horizontal)
                .background(Color("AppBackground"))
                
                VStack(spacing: 6) {
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
                        .onSubmit {
                            addTag()
                        }

                    Button {
                            addTag()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color("AccentColor"))
                        }
                    
                    .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                
                Spacer()
                // MARK: - Bottom Actions
                VStack(spacing: 12) {
                    Button {
                        onSave(draft)
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
                        .ignoresSafeArea(edges: .bottom)
                )
            }.background(Color("AppBackground"))
        }
    }
}

private extension EditSessionView {
    private var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: draft.startTime)
    }

    private var formattedDuration: String {
        let totalSeconds = Int(draft.duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func addTag() {
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
#Preview("Edit Session – Light") {
    EditSessionView(
        session: PracticeSession(
            id: UUID(),
            startTime: Date(),
            duration: 900,
            notes: "Alap practice focusing on slow meend and tone clarity.",
            tags: []
        ),
        onSave: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("Edit Session – Dark") {
    EditSessionView(
        session: PracticeSession(
            id: UUID(),
            startTime: Date(),
            duration: 900,
            notes: "Alap practice focusing on slow meend and tone clarity.",
            tags: []
        ),
        onSave: { _ in }
    )
    .preferredColorScheme(.dark)
}

