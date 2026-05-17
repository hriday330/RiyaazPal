//
//  SetupView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-23.
//

import Foundation
import SwiftUI
import SwiftData

enum SetupStep: Int, CaseIterable {
    case welcome
    case iCloudRestore
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

    let modelContainer: ModelContainer
    let onICloudPreferenceChanged: (Bool) -> Void

    @State private var step: SetupStep = .welcome
    @State private var didSkipPracticeAreasForRestore = false
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @AppStorage(RiyaazPalModelContainer.iCloudSyncEnabledKey)
    private var iCloudSyncEnabled = false

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

        case .iCloudRestore:
            SetupICloudRestoreView(
                onRestore: restoreFromICloud,
                onStartFresh: startFresh
            )

        case .practiceAreas:
            PracticeAreasPanel()
                .modelContainer(modelContainer)
                .safeAreaInset(edge: .bottom) {
                    setupStepControls(
                        primaryTitle: "Continue",
                        secondaryTitle: "Skip for now"
                    )
                }

        case .notifications:
            PracticeNudgeSettingsView()
                .modelContainer(modelContainer)
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
        if step == .notifications && didSkipPracticeAreasForRestore {
            step = .iCloudRestore
            return
        }

        step = step.previous() ?? .welcome
    }

    private func restoreFromICloud() {
        iCloudSyncEnabled = true
        didSkipPracticeAreasForRestore = true
        onICloudPreferenceChanged(true)
        step = .notifications
    }

    private func startFresh() {
        iCloudSyncEnabled = false
        didSkipPracticeAreasForRestore = false
        onICloudPreferenceChanged(false)
        step = .practiceAreas
    }
}

private struct SetupICloudRestoreView: View {
    let onRestore: () -> Void
    let onStartFresh: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 52))
                .foregroundStyle(Color("AccentColor"))

            VStack(spacing: 8) {
                Text("Restore from iCloud?")
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("If you have used RiyaazPal before, restore your practice sessions, areas, and ratings from iCloud. If you are starting fresh, you can set things up now.")
                    .font(.body)
                    .foregroundStyle(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button("Restore from iCloud") {
                    onRestore()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .font(.headline)

                Button("Don't Restore") {
                    onStartFresh()
                }
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
            }
        }
        .padding()
    }
}

#Preview("Setup Flow") {
    NavigationStack {
        SetupView(
            modelContainer: RiyaazPalModelContainer.make(isICloudSyncEnabled: false)
        ) { _ in }
    }
}
