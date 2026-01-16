//
//  EditSessionDetailedNotesEditor.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-16.
//

import Foundation
import SwiftUI

struct EditSessionNotesEditor: View {
    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))
                .padding(.horizontal)

            ZStack(alignment: .topLeading) {
                if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("What felt good? What needs work?")
                        .foregroundStyle(Color("SecondaryText"))
                        .padding(.top, 20)
                        .padding(.leading, 18)
                }

                TextEditor(text: $notes)
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
}
