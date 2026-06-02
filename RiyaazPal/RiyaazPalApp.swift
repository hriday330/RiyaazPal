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
            if hasCompletedSetup {
                RootTabView()
                    .environmentObject(tabRouter)
            } else {
                PracticeAreaRestoreGateView {
                    SetupView()
                }
            }
        }
        .modelContainer(RiyaazPalModelContainer.shared)
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

    @StateObject private var iCloudSyncStatusMonitor = ICloudSyncStatusMonitor()

    @State private var hasDismissedICloudSyncStatus = false

    @AppStorage("practiceNudgesEnabled")
    private var practiceNudgesEnabled = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $router.selectedTab) {
                NavigationStack {
                    PracticeTimelineView()
                        .environmentObject(iCloudSyncStatusMonitor)
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
            .background {
                if practiceNudgesEnabled {
                    PracticeNudgeRefreshTask()
                }

                PracticeAreaSnapshotSyncTask()
            }

            iCloudSyncStatusBanner
        }
    }

    @ViewBuilder
    private var iCloudSyncStatusBanner: some View {
        if iCloudSyncStatusMonitor.isSyncing && !hasDismissedICloudSyncStatus {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.mini)

                Text("Syncing iCloud")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color("SecondaryText"))

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        hasDismissedICloudSyncStatus = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color("SecondaryText"))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 10)
            .padding(.trailing, 6)
            .padding(.vertical, 7)
            .background(Color("CardBackground").opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color("SecondaryText").opacity(0.12), lineWidth: 1)
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: iCloudSyncStatusMonitor.isSyncing)
        }
    }
}

private struct PracticeAreaRestoreGateView<Content: View>: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PracticeAreaEntity.order)
    private var practiceAreas: [PracticeAreaEntity]

    @AppStorage("hasCompletedSetup")
    private var hasCompletedSetup = false

    @State private var isCheckingCloudMirror = true

    let content: () -> Content

    var body: some View {
        Group {
            if isCheckingCloudMirror {
                VStack(spacing: 12) {
                    ProgressView()

                    Text("Checking iCloud")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color("SecondaryText"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("AppBackground"))
            } else {
                content()
            }
        }
        .task {
            await restorePracticeAreasIfAvailable()
        }
    }
}

private extension PracticeAreaRestoreGateView {
    @MainActor
    func restorePracticeAreasIfAvailable() async {
        guard isCheckingCloudMirror else { return }

        if !practiceAreas.isEmpty {
            PracticeAreaSnapshotStore.save(areas: practiceAreas)
            hasCompletedSetup = true
            return
        }

        if PracticeAreaSnapshotStore.restoreInto(
            context: modelContext,
            existingAreas: practiceAreas
        ) {
            hasCompletedSetup = true
            return
        }

        try? await Task.sleep(nanoseconds: 1_500_000_000)

        if !practiceAreas.isEmpty {
            PracticeAreaSnapshotStore.save(areas: practiceAreas)
            hasCompletedSetup = true
            return
        }

        if PracticeAreaSnapshotStore.restoreInto(
            context: modelContext,
            existingAreas: practiceAreas
        ) {
            hasCompletedSetup = true
            return
        }

        isCheckingCloudMirror = false
    }
}

private struct PracticeAreaSnapshotSyncTask: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PracticeAreaEntity.order)
    private var practiceAreas: [PracticeAreaEntity]

    @State private var lastMirroredSignature = ""

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task {
                mirrorPracticeAreasIfNeeded()
            }
            .onChange(of: practiceAreasSignature) {
                mirrorPracticeAreasIfNeeded()
            }
    }
}

private extension PracticeAreaSnapshotSyncTask {
    var practiceAreasSignature: String {
        practiceAreas
            .map { area in
                [
                    area.id.uuidString,
                    area.name,
                    area.isActive.description,
                    area.order.description,
                    area.lastModified.timeIntervalSinceReferenceDate.description
                ].joined(separator: "|")
            }
            .joined(separator: ";")
    }

    @MainActor
    func mirrorPracticeAreasIfNeeded() {
        guard !practiceAreas.isEmpty else { return }

        let signature = practiceAreasSignature
        guard signature != lastMirroredSignature else { return }

        lastMirroredSignature = signature

        if PracticeAreaSnapshotStore.restoreInto(
            context: modelContext,
            existingAreas: practiceAreas
        ) {
            return
        }

        PracticeAreaSnapshotStore.save(areas: practiceAreas)
    }
}

private struct PracticeNudgeRefreshTask: View {
    @Environment(\.modelContext) private var modelContext

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
    func refreshDailyNudgeOnce() async {
        guard !hasRefreshed else { return }
        hasRefreshed = true

        guard practiceNudgesEnabled else { return }

        _ = await PracticeNudgeNotificationService.refreshDailyNudgeIfPossible(
            isEnabled: practiceNudgesEnabled,
            recommendations: rankedPracticeRecommendations(),
            hour: practiceNudgeHour,
            minute: practiceNudgeMinute
        )
    }

    func rankedPracticeRecommendations() -> [PracticeSuggestionRecommendation] {
        let sessions = (try? modelContext.fetch(
            FetchDescriptor<PracticeSession>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        )) ?? []
        let practiceAreas = (try? modelContext.fetch(
            FetchDescriptor<PracticeAreaEntity>(
                sortBy: [SortDescriptor(\.order)]
            )
        )) ?? []
        let practiceAreaRatings = (try? modelContext.fetch(
            FetchDescriptor<PracticeAreaRatingEntity>(
                sortBy: [SortDescriptor(\.createdAt)]
            )
        )) ?? []

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: practiceAreas,
            ratings: practiceAreaRatings,
            sessions: sessions
        )

        return PracticeSuggestionRecommender.rankedRecommendations(
            from: metrics
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
