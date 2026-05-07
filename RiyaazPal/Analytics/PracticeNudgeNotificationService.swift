//
//  PracticeNudgeNotificationService.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-07.
//

import Foundation
import UserNotifications

enum PracticeNudgeNotificationService {

    static let dailyIdentifier = "practiceNudge.daily"
    static let routeUserInfoKey = "route"
    static let timelineRoute = "timeline"

    static func scheduleDailyNudge(
        recommendation: PracticeRecommendation,
        hour: Int,
        minute: Int
    ) async throws {
        let content = notificationContent(for: recommendation)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        try await replaceNotification(
            identifier: dailyIdentifier,
            content: content,
            trigger: trigger
        )
    }

    static func cancelDailyNudge() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [dailyIdentifier]
        )
    }

    static func refreshDailyNudgeIfPossible(
        isEnabled: Bool,
        recommendations: [PracticeSuggestionRecommendation],
        hour: Int,
        minute: Int
    ) async -> PracticeNudgeRefreshResult {
        guard isEnabled else {
            return .disabled
        }

        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return .notificationsUnavailable
        }

        guard let recommendation = await currentRecommendation(from: recommendations) else {
            return .noRecommendation
        }

        do {
            try await scheduleDailyNudge(
                recommendation: recommendation,
                hour: hour,
                minute: minute
            )
            return .scheduled
        } catch {
            return .failed
        }
    }
}

private extension PracticeNudgeNotificationService {

    static func currentRecommendation(
        from recommendations: [PracticeSuggestionRecommendation]
    ) async -> PracticeRecommendation? {
        guard let fallbackRecommendation = recommendations.first else {
            return nil
        }

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return PracticeRecommendationService.fallbackCopy(
                for: fallbackRecommendation
            )
        }

        do {
            return try await PracticeRecommendationSessionCache.generateRecommendation(
                from: recommendations
            )
        } catch {
            let fallbackCopy = PracticeRecommendationService.fallbackCopy(
                for: fallbackRecommendation
            )
            await PracticeRecommendationSessionCache.store(fallbackCopy)
            return fallbackCopy
        }
    }

    static func notificationContent(
        for recommendation: PracticeRecommendation
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = recommendation.title
        content.body = recommendation.body
        content.sound = .default
        content.categoryIdentifier = "practiceNudge"
        content.userInfo = [
            PracticeNudgeNotificationService.routeUserInfoKey: PracticeNudgeNotificationService.timelineRoute
        ]
        return content
    }

    static func replaceNotification(
        identifier: String,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger
    ) async throws {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }
}

enum PracticeNudgeRefreshResult {
    case disabled
    case notificationsUnavailable
    case noRecommendation
    case scheduled
    case failed

    var settingsStatusMessage: String? {
        switch self {
        case .disabled, .notificationsUnavailable:
            return nil
        case .noRecommendation:
            return "Add a practice area to schedule reminders."
        case .scheduled:
            return "Reminder scheduled."
        case .failed:
            return "Could not schedule reminder."
        }
    }
}
