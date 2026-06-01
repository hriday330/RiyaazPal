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
    case practiceAreas
    case notifications
    case done

    func next() -> SetupStep? {
        SetupStep(rawValue: rawValue + 1)
    }

    func previous() -> SetupStep? {
        SetupStep(rawValue: rawValue - 1)
    }
}


struct SetupView: View {

    @State private var step: SetupStep = .welcome
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if step != .welcome {
                            Button {
                                goBack()
                            } label: {
                                Label("Back", systemImage: "chevron.left")
                            }
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            SetupWelcomeView {
                advance()
            }

        case .practiceAreas:
            PracticeAreasPanel()
                .safeAreaInset(edge: .bottom) {
                    setupStepControls(
                        primaryTitle: "Continue",
                        secondaryTitle: "Skip for now"
                    )
                }

        case .notifications:
            PracticeNudgeOnboardingView()
                .safeAreaInset(edge: .bottom) {
                    setupStepControls(
                        primaryTitle: "Continue",
                        secondaryTitle: "Not now"
                    )
                }

        case .done:
            SetupCompleteView {
                hasCompletedSetup = true
            }
        }
    }

    private func setupStepControls(
        primaryTitle: String,
        secondaryTitle: String
    ) -> some View {
        VStack(spacing: 10) {
            Button(primaryTitle) {
                advance()
            }
            .font(.headline)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)

            Button(secondaryTitle) {
                advance()
            }
            .font(.subheadline)
            .foregroundStyle(Color("SecondaryText"))
        }
        .padding()
        .background(
            Color("AppBackground")
                .shadow(.drop(color: .black.opacity(0.08), radius: 8, y: -2))
        )
    }

    private func advance() {
        step = step.next() ?? .done
    }

    private func goBack() {
        step = step.previous() ?? .welcome
    }
}


#Preview("Setup Flow") {
    NavigationStack {
        SetupView()
    }
}
