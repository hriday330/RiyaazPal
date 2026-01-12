//
//  DatePicker.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-12.
//

import Foundation

import SwiftUI

struct DateTimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startTime: Date

    var body: some View {
        NavigationStack {
            VStack {
                

                DatePicker(
                    "Start Time",
                    selection: $startTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                HStack(spacing: 8) {
                    quickDateButton("Yesterday", daysAgo: 1)
                    quickDateButton("2 days ago", daysAgo: 2)
                    quickDateButton("Last week", daysAgo: 7)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Start Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(320)])
    }
}

private extension DateTimePickerSheet {
    @ViewBuilder
    private func quickDateButton(_ title: String, daysAgo: Int) -> some View {
        Button {
            startTime = Calendar.current.date(
                byAdding: .day,
                value: -daysAgo,
                to: Date()
            ) ?? Date()

            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color("PrimaryText"))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
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

#Preview("DateTimePickerSheet – Light") {
    @State var startTime = Date()

    return NavigationStack {
        DateTimePickerSheet(startTime: $startTime)
    }
    .preferredColorScheme(.light)
}

#Preview("DateTimePickerSheet – Dark") {
     @State var startTime = Date()

    return NavigationStack {
        DateTimePickerSheet(startTime: $startTime)
    }
    .preferredColorScheme(.dark)
}
