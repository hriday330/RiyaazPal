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
    }
}

private extension SessionCard {

    var header: some View {
        HStack {
            Text(session.notes)
                .font(.headline)
                .lineLimit(2)

            Spacer()
            
            SessionTypeChip(type: session.resolvedSessionType)
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
            FlowLayout(spacing: 8) {
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

    var formattedDuration: String {
        let minutes = Int(session.duration / 60)
        return "\(minutes) min"
    }
}
