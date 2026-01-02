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
    let onSave: (PracticeSession) -> Void
    
    init(session: PracticeSession, onSave: @escaping (PracticeSession) -> Void) {
        _draft = State(initialValue: session)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Session")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("PrimaryText"))
                        .multilineTextAlignment(.center)
                    
                    Divider()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color("AppBackground"))
                // MARK: - Notes Editor
                Form {
                    Section {
                        TextEditor(text: $draft.notes)
                            .font(.title3)
                            .foregroundStyle(Color("PrimaryText"))
                            .frame(minHeight: 220)
                            .scrollContentBackground(.hidden)
                            .padding(.vertical, 12)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color("AppBackground"))
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
            }
        }
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

