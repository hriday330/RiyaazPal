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
