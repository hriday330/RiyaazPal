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
    
    var body: some Scene {
        return WindowGroup{
            AppBootstrapView{
                
                if hasCompletedSetup {
                    RootTabView()
                        .environmentObject(tabRouter)
                } else {
                    SetupView()
                }
                
                
            }
        }
        .modelContainer(for: [
            PracticeSession.self,
            TagCategoryModel.self,
            GoalEntity.self,
            PracticeAreaEntity.self,
            PracticeAreaRatingEntity.self
        ])
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

struct AppBootstrapView<Content: View>: View {
    @Environment(\.modelContext) private var context
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .task {
                do {
                    try seedDefaultTagCategoriesIfNeeded(context: context)
                } catch {
                    assertionFailure("Failed to seed tag categories: \(error)")
                }
            }
    }
}

final class TabRouter: ObservableObject {
    @Published var selectedTab: Tab = .timeline

    enum Tab {
        case timeline, insights
    }
}
