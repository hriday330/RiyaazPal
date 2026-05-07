//
//  PracticeNudgeSettingsView.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-07.
//

import SwiftUI
import SwiftData
import UIKit
import UserNotifications

struct PracticeNudgeSettingsView: View {

    @Query(sort: \PracticeSession.startTime, order: .reverse)
    private var sessions: [PracticeSession]

    @Query(sort: \PracticeAreaEntity.order)
    private var practiceAreas: [PracticeAreaEntity]

    @Query(sort: \PracticeAreaRatingEntity.createdAt)
    private var practiceAreaRatings: [PracticeAreaRatingEntity]

    @AppStorage("practiceNudgesEnabled")
    private var practiceNudgesEnabled = false

    @AppStorage("practiceNudgeHour")
    private var practiceNudgeHour = 9

    @AppStorage("practiceNudgeMinute")
    private var practiceNudgeMinute = 0

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequestingPermission = false
    @State private var notificationStatusMessage: String?

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
                Text("Choose when practice reminders should appear.")
            }

            Section {
                HStack {
                    Text("Permission")
                    Spacer()
                    Text(permissionText)
                        .foregroundStyle(.secondary)
                }

                if authorizationStatus == .denied {
                    Button("Open Settings") {
                        openSystemSettings()
                    }
                }

                if let notificationStatusMessage {
                    Text(notificationStatusMessage)
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
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
            if practiceNudgesEnabled {
                await scheduleDailyNotification()
            }
        }
        .onChange(of: authorizationStatus) { _, newStatus in
            if newStatus == .denied {
                practiceNudgesEnabled = false
                PracticeNudgeNotificationService.cancelDailyNudge()
            }
        }
        .onChange(of: practiceNudgeHour) { _, _ in
            guard practiceNudgesEnabled else { return }
            Task { await scheduleDailyNotification() }
        }
        .onChange(of: practiceNudgeMinute) { _, _ in
            guard practiceNudgesEnabled else { return }
            Task { await scheduleDailyNotification() }
        }
    }
}

private extension PracticeNudgeSettingsView {

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

    var practiceAreaMetrics: [PracticeAreaMetric] {
        PracticeAreaMetricsCalculator.compute(
            practiceAreas: practiceAreas,
            ratings: practiceAreaRatings,
            sessions: sessions
        )
    }

    var rankedPracticeRecommendations: [PracticeSuggestionRecommendation] {
        PracticeSuggestionRecommender.rankedRecommendations(
            from: practiceAreaMetrics
        )
    }

    func handleNudgeToggle(_ isEnabled: Bool) {
        guard isEnabled else {
            practiceNudgesEnabled = false
            PracticeNudgeNotificationService.cancelDailyNudge()
            notificationStatusMessage = nil
            return
        }

        Task {
            await requestNotificationPermission()
            if practiceNudgesEnabled {
                await scheduleDailyNotification()
            }
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

    func scheduleDailyNotification() async {
        let result = await PracticeNudgeNotificationService.refreshDailyNudgeIfPossible(
            isEnabled: practiceNudgesEnabled,
            recommendations: rankedPracticeRecommendations,
            hour: practiceNudgeHour,
            minute: practiceNudgeMinute
        )
        notificationStatusMessage = result.settingsStatusMessage
    }

    func openSystemSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }

        UIApplication.shared.open(settingsURL)
    }
}

#Preview("Practice Nudges") {
    NavigationStack {
        PracticeNudgeSettingsView()
    }
}
