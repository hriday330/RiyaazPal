//
//  TagChip.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-02.
//

import Foundation

import SwiftUI

struct TagChip: View {
    let tag: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag.fill")
                .font(.caption)
                .foregroundStyle(Color("AccentColor"))

            Text(tag)
                .font(.subheadline)
                .foregroundStyle(Color("PrimaryText"))

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(minHeight:36)
        .background(
            Capsule()
                .fill(Color("CardBackground"))
        )
        .overlay(
            Capsule()
                .stroke(Color("AccentColor").opacity(0.15))
        )
    }
}
