//
//  RiyaazPalApp.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-29.
//

import SwiftUI
import SwiftData
import UIKit
import UserNotifications

@main
struct RiyaazPalApp: App {

    @UIApplicationDelegateAdaptor(RiyaazPalAppDelegate.self)
    private var appDelegate
    
    @AppStorage("hasCompletedSetup")
    private var hasCompletedSetup: Bool = false
    
    @StateObject private var tabRouter = TabRouter()

    @State private var modelContainer = RiyaazPalModelContainer.makeFromStoredPreference()
    
    var body: some Scene {
        return WindowGroup{
            if hasCompletedSetup {
                RootTabView()
                    .environmentObject(tabRouter)
            } else {
                SetupView(onICloudPreferenceChanged: updateModelContainer)
            }
        }
        .modelContainer(modelContainer)
    }

    private func updateModelContainer(iCloudSyncEnabled: Bool) {
        modelContainer = RiyaazPalModelContainer.make(
            isICloudSyncEnabled: iCloudSyncEnabled
        )
    }
}

final class RiyaazPalAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.notification.request.content.userInfo[PracticeNudgeNotificationService.routeUserInfoKey] as? String == PracticeNudgeNotificationService.timelineRoute else {
            return
        }

        await MainActor.run {
            NotificationCenter.default.post(
                name: .practiceNudgeNotificationTapped,
                object: nil
            )
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject var router: TabRouter
    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                PracticeTimelineView()
            }
            .tabItem {
                Label("Timeline", systemImage: "music.note.list")
            }
            .tag(TabRouter.Tab.timeline)
            
            NavigationStack {
                InsightsView()
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar")
            }
            .tag(TabRouter.Tab.insights)
        }
        .onReceive(NotificationCenter.default.publisher(for: .practiceNudgeNotificationTapped)) { _ in
            router.selectedTab = .timeline
        }
        .background(PracticeNudgeRefreshTask())
    }
}

private struct PracticeNudgeRefreshTask: View {
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

    @State private var hasRefreshed = false

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task {
                await refreshDailyNudgeOnce()
            }
    }
}

private extension PracticeNudgeRefreshTask {
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

    func refreshDailyNudgeOnce() async {
        guard !hasRefreshed else { return }
        hasRefreshed = true

        _ = await PracticeNudgeNotificationService.refreshDailyNudgeIfPossible(
            isEnabled: practiceNudgesEnabled,
            recommendations: rankedPracticeRecommendations,
            hour: practiceNudgeHour,
            minute: practiceNudgeMinute
        )
    }
}

final class TabRouter: ObservableObject {
    @Published var selectedTab: Tab = .timeline

    enum Tab {
        case timeline, insights
    }
}

enum FirstRunGuidanceKeys {
    static let timelineStartTip = "hasSeenTimelineStartTip"
    static let postLogInsightsTip = "hasSeenPostLogInsightsTip"
    static let reflectionTip = "hasSeenReflectionTip"
    static let insightsTip = "hasSeenInsightsTip"

    static func reset() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: timelineStartTip)
        defaults.set(false, forKey: postLogInsightsTip)
        defaults.set(false, forKey: reflectionTip)
        defaults.set(false, forKey: insightsTip)
    }
}

struct FirstRunGuidanceCard: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let actionSystemImage: String?
    let onAction: (() -> Void)?
    let onDismiss: () -> Void

    init(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String? = nil,
        actionSystemImage: String? = nil,
        onAction: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.onAction = onAction
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(Color("AccentColor"))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("PrimaryText"))

                Text(message)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle, let onAction {
                    Button(action: onAction) {
                        Label(
                            actionTitle,
                            systemImage: actionSystemImage ?? "arrow.right"
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color("AccentColor"))
                    .padding(.top, 4)
                }
            }

            Spacer(minLength: 8)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("SecondaryText"))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss tip")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("AccentColor").opacity(0.16), lineWidth: 1)
        )
    }
}
