//
//  SetupView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-23.
//

import Foundation
import SwiftUI

enum SetupStep {
    case preferences
}

struct SetupView: View {
    @State private var step: SetupStep = .preferences
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    
    var body: some View {
        NavigationStack {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch step {
        case .preferences:
            PreferencesSetupView {
                // go to the next step
            }
        }
    }
}
