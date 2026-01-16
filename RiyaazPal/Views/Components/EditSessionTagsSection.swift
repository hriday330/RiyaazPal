//
//  EditSessionTagsSection.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-16.
//

import Foundation
import SwiftUI

struct EditSessionTagsSection: View {

    @Binding var tags: [String]
    @Binding var newTag: String
    let onAddTag: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tags")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))
                .padding(.horizontal)

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(
                        tag: tag,
                        onDelete: {
                            tags.removeAll { $0 == tag }
                        }
                    )
                }
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit(onAddTag)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("EditorBorder"), lineWidth: 1)
                    )

                Button(action: onAddTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color("AccentColor"))
                }
                .disabled(
                    newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
            .padding(.horizontal)
        }
    }
}
