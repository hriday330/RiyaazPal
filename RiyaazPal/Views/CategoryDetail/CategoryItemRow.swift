//
//  CategoryItemRow.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-20.
//

import Foundation
import SwiftUI

struct CategoryItemRow: View {

    let title: String
    
    let isEditing: Bool
    let onBeginEditing: () -> Void
    let onCommit: (String) -> Void

    @State private var draft: String

    init(
        title: String,
        isEditing: Bool,
        onBeginEditing: @escaping () -> Void,
        onCommit: @escaping (String) -> Void
    ) {
        self.title = title
        self.isEditing = isEditing
        self.onBeginEditing = onBeginEditing
        self.onCommit = onCommit
        _draft = State(initialValue: title)
    }
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color("AccentColor").opacity(0.6))
                .frame(width: 4, height: 28)

            if isEditing {
                TextField("Tag name", text: $draft)
                    .font(.body.weight(.medium))
                    .submitLabel(.done)
                    .onSubmit { commit() }
            } else {
                Text(title.capitalized)
                    .font(.body.weight(.medium))
                    .onTapGesture {
                        onBeginEditing()
                    }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        
    }
    
    private func commit() {
        let trimmed = draft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !trimmed.isEmpty else {
            draft = title
            return
        }

        onCommit(trimmed)
    }
}
