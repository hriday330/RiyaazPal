//
//  SetupWelcomeView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-25.
//

import Foundation
import SwiftUI

struct SetupWelcomeView: View {

    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to RiyaazPal")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Let’s personalize your practice space. You can change everything later.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Get Started") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.headline)
        }
        .padding()
    }
}
