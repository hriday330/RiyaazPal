//
//  RepertoireRepeatCard.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-15.
//

import Foundation
import SwiftUI

struct RepertoireRepeatCard: View {
    let sessions: [PracticeSession]
    let categorizer: TagCategorizer

    private var topRagas: [(raga: String, count: Int)] {
        let ragaTags = sessions.flatMap { session in
            session.tags.filter { tag in
                categorizer.isRaga(for: tag)
            }
        }

        let counts = Dictionary(grouping: ragaTags.map { $0.lowercased() }) { $0 }
            .mapValues { $0.count }

        return counts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { ($0.key.capitalized, $0.value) }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Most Performed Ragas")
                .font(.headline)

            if topRagas.isEmpty {
                Text("No raga patterns detected in concerts yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
            } else {
                VStack(spacing: 10) {
                    ForEach(topRagas, id: \.raga) { item in
                        ragaRow(name: item.raga, count: item.count)
                    }
                }
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.08), radius: 10)
    }

    private func ragaRow(name: String, count: Int) -> some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Text("\(count)x")
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("AccentColor").opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

private extension View {
    func insightCard(background: Color = Color("CardBackground")) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
    }
}

