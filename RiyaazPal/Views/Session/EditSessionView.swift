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
            Form {
                Section(header: Text("Title")) {
                    TextField("Session title", text: $draft.notes)
                }

            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                }
            }
        }
    }
}


