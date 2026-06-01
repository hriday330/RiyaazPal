//
//  PracticeNudgeOnboardingView.swift
//  RiyaazPal
//
//  Created by Codex on 2026-06-01.
//

import SwiftUI
import UserNotifications

struct PracticeNudgeOnboardingView: View {

    @AppStorage("practiceNudgesEnabled")
    private var practiceNudgesEnabled = false

    @AppStorage("practiceNudgeHour")
    private var practiceNudgeHour = 9

    @AppStorage("practiceNudgeMinute")
    private var practiceNudgeMinute = 0

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequestingPermission = false

    var body: some View {
        List {
            Section {
                Toggle(
                    "Practice nudges",
                    isOn: Binding(
                        get: { practiceNudgesEnabled },
                        set: handleNudgeToggle
                    )
                )
                .disabled(isRequestingPermission)

                DatePicker(
                    "Preferred time",
                    selection: preferredTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!practiceNudgesEnabled)
            } footer: {
                Text("Choose when practice reminders should appear. RiyaazPal will schedule your reminder after setup finishes.")
            }

            Section {
                HStack {
                    Text("Permission")
                    Spacer()
                    Text(permissionText)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color("AppBackground"))
        .scrollContentBackground(.hidden)
        .navigationTitle("Practice Nudges")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshAuthorizationStatus()
            if authorizationStatus == .denied {
                practiceNudgesEnabled = false
                PracticeNudgeNotificationService.cancelDailyNudge()
            }
        }
    }
}

private extension PracticeNudgeOnboardingView {

    var preferredTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: practiceNudgeHour,
                    minute: practiceNudgeMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                practiceNudgeHour = components.hour ?? practiceNudgeHour
                practiceNudgeMinute = components.minute ?? practiceNudgeMinute
            }
        )
    }

    var permissionText: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Not requested"
        case .denied:
            return "Off"
        case .authorized:
            return "Allowed"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Temporary"
        @unknown default:
            return "Unknown"
        }
    }

    func handleNudgeToggle(_ isEnabled: Bool) {
        guard isEnabled else {
            practiceNudgesEnabled = false
            PracticeNudgeNotificationService.cancelDailyNudge()
            return
        }

        Task {
            await requestNotificationPermission()
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestNotificationPermission() async {
        isRequestingPermission = true
        defer { isRequestingPermission = false }

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await refreshAuthorizationStatus()
            practiceNudgesEnabled = granted
            if !granted {
                PracticeNudgeNotificationService.cancelDailyNudge()
            }
        } catch {
            practiceNudgesEnabled = false
            PracticeNudgeNotificationService.cancelDailyNudge()
            await refreshAuthorizationStatus()
        }
    }
}

#Preview("Practice Nudge Onboarding") {
    NavigationStack {
        PracticeNudgeOnboardingView()
    }
}
