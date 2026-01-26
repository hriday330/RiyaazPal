//
//  SetupCompleteView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-25.
//

import Foundation
import SwiftUI

struct SetupCompleteView: View {

    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("You’re all set")
                .font(.title)

            Button("Start Practicing") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
