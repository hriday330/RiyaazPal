//
//  FilterChip.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-15.
//

import Foundation
import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : Color("PrimaryText"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color("AccentColor") : Color("CardBackground"))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.gray.opacity(isSelected ? 0 : 0.2))
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}
