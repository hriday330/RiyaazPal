//
//  SessionCard.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-31.
//

import Foundation
import SwiftUI

struct SessionCard: View {
    let session: PracticeSession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            footer

            if !session.tags.isEmpty {
                tagRow
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

private extension SessionCard {

    var header: some View {
        HStack {
            Text(session.notes)
                .font(.headline)
                .lineLimit(2)

            Spacer()

            Text(formattedDuration)
                .font(.caption)
                .padding(6)
                .background(.thinMaterial)
                .clipShape(Capsule())
        }
    }

    var footer: some View {
        Text(session.startTime, style: .time)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(session.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
    }

    var formattedDuration: String {
        let minutes = Int(session.duration / 60)
        return "\(minutes) min"
    }
}

#Preview {
    SessionCard(
        session: PracticeSession(
            startTime: Date(),
            duration: 45 * 60,
            notes: "Taan practice – drut teentaal",
            tags: ["Raga Puriya", "Taan", "Technical"]
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
