//
//  RepertoireNeglectCard.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-25.
//

import Foundation
import SwiftUI

struct RepertoireNeglectCard: View {
    let practiceSessions: [PracticeSession]
    let concertSessions: [PracticeSession]
    let categorizer: TagCategorizer

    // ragas practiced recently
    private var practicedRagas: [String] {
        practiceSessions
            .flatMap { session in
                session.tags.filter { categorizer.isRaga(for: $0) }
            }
            .map { $0.lowercased() }
    }

    // ragas performed in concerts
    private var performedRagas: Set<String> {
        Set(
            concertSessions
                .flatMap { session in
                    session.tags.filter { categorizer.isRaga(for: $0) }
                }
                .map { $0.lowercased() }
        )
    }

    // practiced often but never performed
    private var neglectedRagas: [(raga: String, count: Int)] {
        let counts = Dictionary(grouping: practicedRagas) { $0 }
            .mapValues { $0.count }

        return counts
            .filter { !performedRagas.contains($0.key) }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { ($0.key.capitalized, $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            header

            if neglectedRagas.isEmpty {
                Text("Your recent practice is well represented in concerts.")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
            } else {
                VStack(spacing: 12) {
                    ForEach(neglectedRagas, id: \.raga) { item in
                        ragaRow(name: item.raga, count: item.count)
                    }

                    if let neglectInsight {
                        Text(neglectInsight)
                            .font(.caption)
                            .foregroundStyle(Color("SecondaryText"))
                            .padding(.top, 6)
                    }
                }
            }
        }
        .insightCard()
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color("AccentColor").opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 8)
    }
    
    
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color("AccentColor").opacity(0.8))

            Text("Repertoire Gaps")
                .font(.headline)
        }
    }
    
    private func ragaRow(name: String, count: Int) -> some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "music.note")
                    .font(.caption2)

                Text("Practiced \(count)x")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color("AccentColor"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .stroke(Color("AccentColor").opacity(0.25), lineWidth: 1)
            )
        }
        
    }

    private var neglectInsight: String? {
        guard let top = neglectedRagas.first else { return nil }

        switch top.count {
        case 6...:
            return "You’ve been spending significant time on \(top.raga), but it hasn’t appeared in recent concerts yet."
        case 3..<6:
            return "\(top.raga) shows up often in practice, but not in performance recently."
        default:
            return nil
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
