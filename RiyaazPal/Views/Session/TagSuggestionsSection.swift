//
//  TagSuggestionsSection.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-25.
//

import Foundation

import SwiftUI

struct TagSuggestionsSection: View {
    let suggestions: [String]
    let onTap: (String) -> Void

    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {

                Text("Suggested")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))

                FlowLayout(spacing: 8) {
                    ForEach(suggestions, id: \.self) { tag in
                        Button {
                            onTap(tag)
                        } label: {
                            Text(tag)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color("EditorBackground"))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color("EditorBorder"), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
