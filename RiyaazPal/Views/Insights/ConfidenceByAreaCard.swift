//
//  ConfidenceByRagaCard.swift
//  RiyaazPal
//

import SwiftUI
import Charts

struct ConfidenceByRagaCard: View {

    let sessions: [PracticeSession]
    let categorizer: TagCategorizer

    private var ragaConfidence: [(name: String, value: Double)] {

        let pairs = sessions
            .filter { $0.resolvedSessionType == .concert }
            .compactMap { session -> [(String, Int)]? in
                guard let confidence = session.resolvedConfidence else { return nil }

                let ragas = Set(session.tags.filter { categorizer.isRaga(for: $0) })
                return ragas.map { ($0.lowercased(), confidence) }
            }
            .flatMap { $0 }

        let grouped = Dictionary(grouping: pairs, by: { $0.0 })

        return grouped
            .map { key, values in
                let avg = Double(values.map(\.1).reduce(0,+)) / Double(values.count)
                return (key.capitalized, avg)
            }
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { $0 }
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            header

            if ragaConfidence.isEmpty {

                Text("Confidence insights will appear after a few concerts.")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))

            } else {

                Chart {
                    ForEach(ragaConfidence, id: \.name) { item in
                        BarMark(
                            x: .value("Confidence", item.value),
                            y: .value("Raga", item.name)
                        )
                        .foregroundStyle(Color("AccentColor"))
                        .cornerRadius(6)
                        .annotation(position: .trailing) {
                            Text(String(format: "%.1f", item.value))
                                .font(.caption)
                                .foregroundStyle(Color("SecondaryText"))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 160)
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.08), radius: 10)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.circle")
                .foregroundStyle(Color("AccentColor").opacity(0.8))

            Text("Most Confident Ragas")
                .font(.headline)
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
                    .fill(background)
            )
    }
}
