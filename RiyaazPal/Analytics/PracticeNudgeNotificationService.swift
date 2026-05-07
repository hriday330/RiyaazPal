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
}

private extension PracticeNudgeNotificationService {

    static func notificationContent(
        for recommendation: PracticeRecommendation
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = recommendation.title
        content.body = recommendation.body
        content.sound = .default
        content.categoryIdentifier = "practiceNudge"
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
