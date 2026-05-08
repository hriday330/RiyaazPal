//
//  SetupView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-23.
//

import Foundation
import SwiftUI

enum SetupStep: Int, CaseIterable {
    case welcome
    case done

    func next() -> SetupStep? {
        SetupStep(rawValue: rawValue + 1)
    }
}


struct SetupView: View {

    @State private var step: SetupStep = .welcome
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false

    var body: some View {
        NavigationStack {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            SetupWelcomeView {
                advance()
            }

        case .done:
            SetupCompleteView {
                hasCompletedSetup = true
            }
        }
    }

    private func advance() {
        step = step.next() ?? .done
    }
}


#Preview("Setup Flow") {
    NavigationStack {
        SetupView()
    }
}
