//
//  MonthStepper.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-18.
//

import Foundation
import SwiftUI
struct MonthStepper: View {
    let month: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    let hasMoreOlderSessions: Bool
    let oldestLoadedSessionDate: Date?

    private var label: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private var canStepToPreviousMonth: Bool {
        guard let oldestLoadedSessionDate else { return hasMoreOlderSessions }

        return hasMoreOlderSessions ||
            !Calendar.current.isDate(month, equalTo: oldestLoadedSessionDate, toGranularity: .month)
    }

    var body: some View {
        HStack {
            Button {
                onPrevious()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!canStepToPreviousMonth)

            Spacer()

            Text(label)
                .font(.headline)

            Spacer()

            Button {
                onNext()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(Calendar.current.isDate(month, equalTo: Date(), toGranularity: .month))

        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color("AppBackground"))
    }
}
