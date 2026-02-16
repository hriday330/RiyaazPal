//
//  ConcertFrequencyCard.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-15.
//

import Foundation
import SwiftUI

struct ConcertFrequencyCard: View {
    let concerts: [PracticeSession]

    private var totalConcerts: Int {
        concerts.count
    }

    private var concertsThisMonth: Int {
        let calendar = Calendar.current
        return concerts.filter {
            calendar.isDate($0.startTime, equalTo: Date(), toGranularity: .month)
        }.count
    }

    private var lastConcertDate: Date? {
        concerts.first?.startTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Performance Frequency")
                .font(.headline)

            HStack(spacing: 24) {
                metric(
                    value: "\(totalConcerts)",
                    label: "This period"
                )

                metric(
                    value: "\(concertsThisMonth)",
                    label: "This month"
                )

                metric(
                    value: lastConcertText,
                    label: "Last concert"
                )
            }
        }
        .insightCard()
        .shadow(color: .black.opacity(0.08), radius: 10)
    }

    private var lastConcertText: String {
        guard let lastConcertDate else { return "—" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastConcertDate, relativeTo: Date())
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
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

