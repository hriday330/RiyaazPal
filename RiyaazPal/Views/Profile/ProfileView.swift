//
//  ProfileView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-19.
//

import Foundation

import SwiftUI
import SwiftData

private enum ProfileRoute: Hashable {
    case practiceAreas
    case practiceNudges
}

struct ProfileView: View {

    @Query(sort: \PracticeAreaEntity.order)
    private var practiceAreas: [PracticeAreaEntity]
    
    @Environment(\.dismiss)
    private var dismiss

    @AppStorage(RiyaazPalModelContainer.iCloudSyncEnabledKey)
    private var iCloudSyncEnabled = true

    @State private var showICloudRestartNote = false

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            List {
                
                // MARK: Practice Areas Section
                Section {
                    NavigationLink(value: ProfileRoute.practiceAreas) {
                        PracticeAreasRow(areas: practiceAreas)
                    }
                } header: {
                    Text("Practice Areas")
                } footer: {
                    Text("Define the skill areas you'll rate after practice sessions.")
                }

                // MARK: Practice Nudges Section
                Section {
                    NavigationLink(value: ProfileRoute.practiceNudges) {
                        PracticeNudgesRow()
                    }
                } header: {
                    Text("Practice Nudges")
                } footer: {
                    Text("Choose whether practice reminders are allowed.")
                }

                // MARK: iCloud Section
                Section {
                    Toggle(
                        "iCloud sync",
                        isOn: Binding(
                            get: { iCloudSyncEnabled },
                            set: updateICloudSyncPreference
                        )
                    )

                    if showICloudRestartNote {
                        Label(
                            "Restart RiyaazPal to apply this change.",
                            systemImage: "arrow.clockwise"
                        )
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                    }
                } header: {
                    Text("iCloud")
                } footer: {
                    Text("When enabled, practice sessions, practice areas, and ratings sync through your private iCloud account.")
                }

                #if DEBUG
                Section {
                    Button {
                        FirstRunGuidanceKeys.reset()
                    } label: {
                        Label("Reset First-Run Tips", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Replay timeline, reflection, and insights guidance without clearing app data.")
                }
                #endif
            }
            .listStyle(.insetGrouped)
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .practiceAreas:
                    PracticeAreasPanel()
                case .practiceNudges:
                    PracticeNudgeSettingsView()
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                }
                .accessibilityLabel("Close")
            }
        }
    }

    private func updateICloudSyncPreference(_ isEnabled: Bool) {
        iCloudSyncEnabled = isEnabled
        showICloudRestartNote = true
    }
}

private struct PracticeAreasRow: View {
    let areas: [PracticeAreaEntity]

    private var activeAreas: [PracticeAreaEntity] {
        areas.filter(\.isActive)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Practice Areas")
                    .font(.body)
                    .fontWeight(.medium)

                if activeAreas.isEmpty {
                    Text("No areas set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(activeAreas.count) active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "slider.horizontal.3")
                .foregroundStyle(Color("AccentColor"))
        }
        .padding(.vertical, 4)
    }
}

private struct PracticeNudgesRow: View {

    @AppStorage("practiceNudgesEnabled")
    private var practiceNudgesEnabled = false

    @AppStorage("practiceNudgeHour")
    private var practiceNudgeHour = 9

    @AppStorage("practiceNudgeMinute")
    private var practiceNudgeMinute = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Practice Reminders")
                    .font(.body)
                    .fontWeight(.medium)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "bell.badge")
                .foregroundStyle(Color("AccentColor"))
        }
        .padding(.vertical, 4)
    }

    private var statusText: String {
        guard practiceNudgesEnabled else { return "Off" }

        let date = Calendar.current.date(
            bySettingHour: practiceNudgeHour,
            minute: practiceNudgeMinute,
            second: 0,
            of: Date()
        ) ?? Date()

        return "On at \(date.formatted(date: .omitted, time: .shortened))"
    }
}

#Preview("Profile – Light") {
    let container = PreviewModelContainer.make()

    return NavigationStack {
        ProfileView()
    }
    .modelContainer(container)
    .preferredColorScheme(.light)
}

#Preview("Profile – Dark") {
    let container = PreviewModelContainer.make()

    return NavigationStack {
        ProfileView()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
