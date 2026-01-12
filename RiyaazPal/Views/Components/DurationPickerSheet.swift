//
//  DurationPickerSheet.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-12.
//

import Foundation
import SwiftUI

struct DurationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var duration: TimeInterval

    @State private var hour: Int
    @State private var minute: Int

    private let hours = Array(0...4)
    private let minutes = stride(from: 0, through: 55, by: 5).map { $0 }

    init(duration: Binding<TimeInterval>) {
        self._duration = duration

        let totalMinutes = Int(duration.wrappedValue) / 60
        _hour = State(initialValue: totalMinutes / 60)
        _minute = State(initialValue: totalMinutes % 60)
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Picker("Hours", selection: $hour) {
                        ForEach(hours, id: \.self) {
                            Text("\($0) hr").tag($0)
                        }
                    }
                    .pickerStyle(.wheel)

                    Picker("Minutes", selection: $minute) {
                        ForEach(minutes, id: \.self) {
                            Text("\($0) min").tag($0)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .padding()
            }
            .navigationTitle("Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        duration = TimeInterval(hour * 3600 + minute * 60)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(260)])
    }
}
