//
//  WelcomeSetupView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-23.
//

import Foundation
import SwiftUI

struct PreferencesSetupView: View {

    let onContinue: () -> Void

    @AppStorage("defaultSessionDuration")
    private var defaultDuration: Int = 45

    var body: some View {
        VStack(spacing: 24) {
            Text("Customize your practice")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Stepper(
                "Default session length: \(defaultDuration) min",
                value: $defaultDuration,
                in: 15...120,
                step: 5
            )

            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
