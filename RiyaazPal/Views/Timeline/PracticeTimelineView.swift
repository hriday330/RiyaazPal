//
//  PracticeTimelineView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-29.
//

import SwiftUI
import SwiftData

struct PracticeTimelineView: View {
    @EnvironmentObject var router: TabRouter

    @Query(sort: \PracticeAreaEntity.order)
        private var practiceAreas: [PracticeAreaEntity]

    @StateObject private var timelineViewModel = PracticeTimelineViewModel()
    
    @Environment(\.modelContext)
    private var context
    
    @StateObject private var sessionViewModel = PracticeSessionViewModel()
    
    @StateObject private var timelineFilterViewModel = TimelineFilterViewModel();
    
    @State private var selectedSession: PracticeSession?

    @State private var selectedMonth: Date = Date()

    @State private var showProfile = false

    @State private var practiceRecommendation: PracticeRecommendation?
    @State private var isPracticeRecommendationLoading = false
    @State private var dismissedPracticeRecommendationID: String?

    @AppStorage(FirstRunGuidanceKeys.timelineStartTip)
    private var hasSeenTimelineStartTip = false

    @AppStorage(FirstRunGuidanceKeys.postLogInsightsTip)
    private var hasSeenPostLogInsightsTip = false
    
    @State private var isScrollingProgrammatically = false
    @State private var showICloudSyncMessage = true

    @AppStorage(RiyaazPalModelContainer.iCloudSyncEnabledKey)
    private var iCloudSyncEnabled = true

    private var sessions: [PracticeSession] {
        timelineViewModel.sessions
    }

    private var shouldShowICloudSyncMessage: Bool {
        iCloudSyncEnabled && showICloudSyncMessage
    }

    private var isShowingTimelineGuidance: Bool {
        !hasSeenTimelineStartTip || (!hasSeenPostLogInsightsTip && !sessions.isEmpty)
    }
    
    var body: some View {
            ZStack {
                // App-wide background
                Color("AppBackground")
                    .ignoresSafeArea()
                if timelineViewModel.isLoadingInitialPage && sessions.isEmpty {
                    VStack(spacing: 16) {
                        iCloudSyncStatusBanner
                        ProgressView()
                    }
                } else if(sessions.isEmpty  && !sessionViewModel.isSessionActive) {
                    VStack(spacing: 16) {
                        iCloudSyncStatusBanner
                        timelineStartGuidanceCard

                        PracticeTimelineEmptyState(isSessionActive: sessionViewModel.isSessionActive, onStartSession: handleSessionAction) {
                            ActiveSessionBar(elapsedTime: sessionViewModel.elapsedTime, action: handleSessionAction)
                        }
                    }
                } else if timelineFilterViewModel.isSearching && timelineFilterViewModel.filteredSessions(from: sessions).isEmpty {
                    PracticeTimelineFilteredEmptyState()
                } else {
                    timelineWithMonthStepper
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .scrollTransition(.interactive) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1.0 : 0.94)
                        }
                    sessionControl
                }
                
            }

            .navigationTitle("RiyaazPal")
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .imageScale(.large)
                    }
                }
            }
            .searchableIf(
                !sessions.isEmpty || sessionViewModel.isSessionActive,
                text: $timelineFilterViewModel.searchText,
                tokens: $timelineFilterViewModel.selectedTags,
                suggestedTokens: timelineFilterViewModel.suggestedTags(from: sessions),
                onSubmit: {
                    timelineFilterViewModel.handleSearchSubmit()
                }
            ).onSubmit(of: .search) {
                timelineFilterViewModel.handleSearchSubmit()
            }
            .sheet(item: $selectedSession) { session in
                EditSessionView(
                    session: session
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }.sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileView()
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .task {
                timelineViewModel.loadInitialPage(context: context)
            }
            .task {
                try? await Task.sleep(for: .seconds(20))
                showICloudSyncMessage = false
            }
            .task(id: recommendationRefreshID) {
                await loadPracticeRecommendation()
            }
            .onReceive(NotificationCenter.default.publisher(for: .practiceNudgeNotificationTapped)) { _ in
                dismissPresentedTimelinePanels()
            }
            
            
        }
}

private extension PracticeTimelineView {
    
    func handleSessionAction() {
        if sessionViewModel.isSessionActive {
            if let session = sessionViewModel.endSession() {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                context.insert(session)
                do {
                    try context.save()
                    timelineViewModel.reloadFirstPage(context: context)
                } catch {
                    // TODO: alert if failed to save
                    print("Failed to save session: \(error.localizedDescription)")
                }
            }
        } else {
            hasSeenTimelineStartTip = true
            sessionViewModel.startSession()
        }
    }

    func handleRecommendationAction() {
        guard !sessionViewModel.isSessionActive else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        sessionViewModel.startSession()
    }

    func dismissPracticeRecommendation() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            dismissedPracticeRecommendationID = recommendationRefreshID
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func dismissTimelineStartGuidance() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            hasSeenTimelineStartTip = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func dismissPostLogInsightsGuidance() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            hasSeenPostLogInsightsTip = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    
    var sessionControl: some View {
        Group {
            if sessionViewModel.isSessionActive {
                ActiveSessionBar(elapsedTime: sessionViewModel.elapsedTime, action: handleSessionAction)
            } else {
                SessionActionButton(isActive: sessionViewModel.isSessionActive, action: handleSessionAction,
                    secondaryAction: {
                        createOldSession()
                    }
                )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85),
                   value: sessionViewModel.isSessionActive)
    }
    
    var timelineList: some View {
        timelineList(
            groups: timelineViewModel.groupedByDay(
                from: timelineFilterViewModel.filteredSessions(from: sessions)
            )
        )
    }

    func timelineList(groups: [(date: Date, sessions: [PracticeSession])]) -> some View {
        List {
            ForEach(groups, id: \.date) { group in
                Section {
                    ForEach(group.sessions) { session in
                        SessionCard(session: session)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedSession = session
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    timelineViewModel.removeSession(session)
                                    context.delete(session)
                                    do {
                                        try context.save()
                                    } catch {
                                        // TODO - alert if failed to save session 
                                        print("Failed to save session: \(error.localizedDescription)")
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowInsets(.init())
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    Text(group.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .onAppear {
                            updateMonthOnScroll(to: group.date)
                            timelineViewModel.loadOlderPageIfNeeded(
                                currentGroupDate: group.date,
                                groups: groups,
                                context: context
                            )
                        }
                }
                .id(Calendar.current.startOfDay(for: group.date))
            }

            if timelineViewModel.isLoadingOlderPage {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
            }
        }
    }
}

private extension PracticeTimelineView {
    var sessionTypeFilterChips: some View {
        HStack(spacing: 8) {
            FilterChip(
                title: "All",
                isSelected: timelineFilterViewModel.sessionTypeFilter == .all
            ) {
                timelineFilterViewModel.sessionTypeFilter = .all
            }

            FilterChip(
                title: "Practice",
                isSelected: timelineFilterViewModel.sessionTypeFilter == .practice
            ) {
                timelineFilterViewModel.sessionTypeFilter = .practice
            }

            FilterChip(
                title: "Concerts",
                isSelected: timelineFilterViewModel.sessionTypeFilter == .concert
            ) {
                timelineFilterViewModel.sessionTypeFilter = .concert
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private extension PracticeTimelineView {
    
    func createOldSession() {
        let session = PracticeSession(
            startTime: Date(),
            duration: 60*60, // 1hr adjust later
            notes: "",
            tags: []
        )

        context.insert(session)

        do {
            try context.save()
            timelineViewModel.reloadFirstPage(context: context)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedSession = session
        } catch {
            print("Failed to create backfill session: \(error)")
        }
    }

    
    var timelineWithMonthStepper: some View {
        ScrollViewReader { proxy in
            let filteredSessions = timelineFilterViewModel.filteredSessions(from: sessions)
            let groupedSessions = timelineViewModel.groupedByDay(from: filteredSessions)

            VStack(spacing: 0) {
                MonthStepper(
                    month: selectedMonth,
                    onPrevious: {
                        shiftMonth(by: -1, proxy: proxy)
                    },
                    onNext: {
                        shiftMonth(by: 1, proxy: proxy)
                    },
                    hasMoreOlderSessions: timelineViewModel.hasMoreOlderSessions,
                    oldestLoadedSessionDate: sessions.last?.startTime
                )
                sessionTypeFilterChips.padding(.top, 8)

                iCloudSyncStatusBanner
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                timelineStartGuidanceCard
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                practiceRecommendationCard

                postLogInsightsGuidanceCard
                
                if (!filteredSessions.isEmpty) {
                    timelineList(groups: groupedSessions)
                } else {
                    PracticeTimelineTypeEmptyState(filter: timelineFilterViewModel.sessionTypeFilter)
                }
                

            }
        }
    }

    @ViewBuilder
    var iCloudSyncStatusBanner: some View {
        if shouldShowICloudSyncMessage {
            ICloudSyncStatusBanner()
                .transition(.opacity)
        }
    }

    @ViewBuilder
    var timelineStartGuidanceCard: some View {
        if !hasSeenTimelineStartTip {
            FirstRunGuidanceCard(
                title: "Start your first loop",
                message: "Tap the practice button to start a live session. Press and hold it to log a prior session.",
                systemImage: "play.circle.fill"
            ) { dismissTimelineStartGuidance() }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder
    var postLogInsightsGuidanceCard: some View {
        if !hasSeenPostLogInsightsTip,
           !sessions.isEmpty,
           !timelineFilterViewModel.isSearching {
            FirstRunGuidanceCard(
                title: "See what changed",
                message: "Once you have logged a session, Insights can show your practice-area trends and attention areas.",
                systemImage: "chart.line.uptrend.xyaxis",
                actionTitle: "Open Insights",
                actionSystemImage: "chart.bar.fill",
                onAction: {
                    hasSeenPostLogInsightsTip = true
                    router.selectedTab = .insights
                }
            ) { dismissPostLogInsightsGuidance() }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder
    var practiceRecommendationCard: some View {
        if (practiceRecommendation != nil || isPracticeRecommendationLoading),
           !isShowingTimelineGuidance,
           dismissedPracticeRecommendationID != recommendationRefreshID,
           !timelineFilterViewModel.isSearching,
           timelineFilterViewModel.sessionTypeFilter != .concert {
            PracticeRecommendationCard(
                recommendation: practiceRecommendation,
                isLoading: isPracticeRecommendationLoading,
                isSessionActive: sessionViewModel.isSessionActive,
                onUseFocus: handleRecommendationAction,
                onDismiss: dismissPracticeRecommendation
            )
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    var recommendationRefreshID: String {
        let practiceAreaValues = practiceAreas.map { area in
                [
                    area.id.uuidString,
                    area.name,
                    "\(area.isActive)",
                    "\(area.order)"
                ].joined(separator: ":")
        }.joined(separator: "|")

        return [
            practiceAreaValues
        ].joined(separator: "#")
    }

    func loadPracticeRecommendation() async {
        let recommendations = await rankedPracticeRecommendations()

        guard let fallbackRecommendation = recommendations.first else {
            practiceRecommendation = nil
            isPracticeRecommendationLoading = false
            return
        }

        if let cachedRecommendation = PracticeRecommendationSessionCache.recommendation {
            practiceRecommendation = cachedRecommendation
            isPracticeRecommendationLoading = false
            return
        }

        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            let fallbackRecommendationCopy = PracticeRecommendationService.fallbackCopy(
                for: fallbackRecommendation
            )
            PracticeRecommendationSessionCache.store(fallbackRecommendationCopy)
            practiceRecommendation = fallbackRecommendationCopy
            isPracticeRecommendationLoading = false
            return
        }

        practiceRecommendation = nil
        isPracticeRecommendationLoading = true

        do {
            practiceRecommendation = try await PracticeRecommendationSessionCache.generateRecommendation(
                from: recommendations
            )
        } catch {
            if error is CancellationError {
                return
            }

            let fallbackRecommendationCopy = PracticeRecommendationService.fallbackCopy(
                for: fallbackRecommendation
            )
            PracticeRecommendationSessionCache.store(fallbackRecommendationCopy)
            practiceRecommendation = fallbackRecommendationCopy
        }

        isPracticeRecommendationLoading = false
    }

    func rankedPracticeRecommendations() async -> [PracticeSuggestionRecommendation] {
        let modelContainer = RiyaazPalModelContainer.shared
        let practiceAreaInputs = practiceAreas.map {
            PracticeAreaMetricAreaInput(
                id: $0.id,
                name: $0.name,
                isActive: $0.isActive,
                order: $0.order
            )
        }
        return await Task.detached(priority: .utility) {
            let context = ModelContext(modelContainer)
            let sessions = (try? context.fetch(
                FetchDescriptor<PracticeSession>(
                    sortBy: [SortDescriptor(\.startTime, order: .reverse)]
                )
            )) ?? []
            let ratings = (try? context.fetch(
                FetchDescriptor<PracticeAreaRatingEntity>(
                    sortBy: [SortDescriptor(\.createdAt)]
                )
            )) ?? []
            let sessionInputs = sessions.map {
                PracticeAreaMetricSessionInput(
                    id: $0.id,
                    startTime: $0.startTime,
                    sessionType: $0.resolvedSessionType,
                    lastModified: $0.lastModified
                )
            }
            let ratingInputs = ratings.map {
                PracticeAreaMetricRatingInput(
                    sessionID: $0.sessionID,
                    practiceAreaID: $0.practiceAreaID,
                    areaName: $0.areaName,
                    didPractice: $0.didPractice,
                    score: $0.score,
                    createdAt: $0.createdAt,
                    lastModified: $0.lastModified
                )
            }
            let metrics = PracticeAreaMetricsCalculator.compute(
                practiceAreas: practiceAreaInputs,
                ratings: ratingInputs,
                sessions: sessionInputs
            )
            return PracticeSuggestionRecommender.rankedRecommendations(from: metrics)
        }.value
    }

    func dismissPresentedTimelinePanels() {
        selectedSession = nil
        showProfile = false
    }

    func shiftMonth(by delta: Int, proxy: ScrollViewProxy) {
        guard
            let newMonth = Calendar.current.date(
                byAdding: .month,
                value: delta,
                to: selectedMonth
            )
        else { return }

        isScrollingProgrammatically = true
        
        selectedMonth = newMonth

        if delta < 0 {
            timelineViewModel.loadUntilMonthExists(newMonth, context: context)
        }

        scrollToMonth(newMonth, proxy: proxy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isScrollingProgrammatically = false
        }
    }

    func updateMonthOnScroll(to date: Date) {
            // If we are currently animating a "Shift Month" click, don't let
            // the scroll listener interfere or it will stutter.
            guard !isScrollingProgrammatically else { return }
            
            let calendar = Calendar.current
            
            if !calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month) {
                selectedMonth = date
            }
        }
    
    func scrollToMonth(_ month: Date, proxy: ScrollViewProxy) {
        let calendar = Calendar.current

        guard let targetDate = timelineViewModel
            .groupedByDay(from: sessions)
            .map(\.date)
            .first(where: {
                calendar.isDate($0, equalTo: month, toGranularity: .month)
            })
        else { return }

        let scrollID = calendar.startOfDay(for: targetDate)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            proxy.scrollTo(scrollID, anchor: .topLeading)
        }
    }
}

extension View {
    @ViewBuilder
    func searchableIf(_ condition: Bool, text: Binding<String>, tokens: Binding<[TagToken]>, suggestedTokens: [TagToken], onSubmit: @escaping () -> Void) -> some View {
        if condition {
            self.searchable(
                text: text,
                tokens: tokens,
                suggestedTokens: .constant(suggestedTokens),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search notes or filter by tag",
                token: { token in
                    Text(token.name)
                }
            )
            .onSubmit(of: .search, onSubmit)
        } else {
            self
        }
    }
}

struct ICloudSyncStatusBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)

            VStack(alignment: .leading, spacing: 2) {
                Text("Syncing from iCloud")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("PrimaryText"))

                Text("Your recent sessions may appear over the next few moments.")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("InsightCardBackground"))
        )
    }
}

#Preview("Practice Timeline – Light") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    context.insert(
        PracticeSession(
            startTime: Date(),
            duration: 45 * 60,
            notes: "Alap practice – slow tempo",
            tags: ["Raga Yaman", "Alap"]
        )
    )

    context.insert(
        PracticeSession(
            startTime: Date().addingTimeInterval(-3600),
            duration: 30 * 60,
            notes: "Meend exercises",
            tags: ["Technique"]
        )
    )

    context.insert(
        PracticeSession(
            startTime: Date().addingTimeInterval(-86_400),
            duration: 60 * 60,
            notes: "Full riyaaz session with tanpura",
            tags: ["Raga Bhairav"]
        )
    )
    
    return NavigationStack {
        PracticeTimelineView()
    }
    .modelContainer(container)
    .preferredColorScheme(.light)
}

#Preview("Practice Timeline – Dark") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    context.insert(
        PracticeSession(
            startTime: Date(),
            duration: 45 * 60,
            notes: "Alap practice – slow tempo",
            tags: ["Raga Yaman", "Alap"]
        )
    )

    context.insert(
        PracticeSession(
            startTime: Date().addingTimeInterval(-3600),
            duration: 30 * 60,
            notes: "Meend exercises",
            tags: ["Technique"]
        )
    )

    context.insert(
        PracticeSession(
            startTime: Date().addingTimeInterval(-86_400),
            duration: 60 * 60,
            notes: "Full riyaaz session with tanpura",
            tags: ["Raga Bhairav"]
        )
    )
    

    return NavigationStack {
        PracticeTimelineView()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
