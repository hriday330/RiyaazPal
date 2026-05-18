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
    case iCloudSync
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
    @AppStorage(RiyaazPalModelContainer.iCloudSyncEnabledKey)
    private var iCloudSyncEnabled = true

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

        case .iCloudSync:
            SetupICloudSyncView {
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
            PracticeNudgeSettingsView()
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
        let nextStep = step.next() ?? .done
        step = nextStep == .iCloudSync && !iCloudSyncEnabled
            ? nextStep.next() ?? .done
            : nextStep
    }

    private func goBack() {
        step = step.previous() ?? .welcome
    }
}

private struct SetupICloudSyncView: View {
    let onContinue: () -> Void

    @State private var canContinue = false

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)

            VStack(spacing: 10) {
                Text("Syncing your practice history")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("If you’ve used RiyaazPal before, your sessions may take a moment to appear from iCloud.")
                    .font(.body)
                    .foregroundStyle(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
            }

            Button(canContinue ? "Continue" : "Checking iCloud...") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.headline)
            .disabled(!canContinue)
        }
        .padding()
        .task {
            guard !canContinue else { return }

            try? await Task.sleep(for: .seconds(4))
            canContinue = true
        }
    }
}


#Preview("Setup Flow") {
    NavigationStack {
        SetupView()
    }
}
