//
//  PracticeTimelineView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-29.
//

import SwiftUI
import SwiftData

struct PracticeTimelineView: View {
    
    @Query(sort: \PracticeSession.startTime, order: .reverse)
        private var sessions: [PracticeSession]

    @StateObject private var timelineViewModel = PracticeTimelineViewModel()
    
    @Environment(\.modelContext)
    private var context
    
    @StateObject private var sessionViewModel = PracticeSessionViewModel()
    
    @StateObject private var timelineFilterViewModel = TimelineFilterViewModel();
    
    @State private var selectedSession: PracticeSession?

    @State private var selectedMonth: Date = Date()

    @State private var showProfile = false
    
    @State private var isScrollingProgrammatically = false
    
    var body: some View {
            ZStack {
                // App-wide background
                Color("AppBackground")
                if(sessions.isEmpty  && !sessionViewModel.isSessionActive) {
                    PracticeTimelineEmptyState(isSessionActive: sessionViewModel.isSessionActive, onStartSession: handleSessionAction) {
                        ActiveSessionBar(elapsedTime: sessionViewModel.elapsedTime, action: handleSessionAction)
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
                } catch {
                    // TODO: alert if failed to save
                    print("Failed to save session: \(error.localizedDescription)")
                }
            }
        } else {
            sessionViewModel.startSession()
        }
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
        List {
            ForEach(timelineViewModel.groupedByDay(from: timelineFilterViewModel.filteredSessions(from: sessions)), id: \.date) { group in
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
                        }
                }
                .id(Calendar.current.startOfDay(for: group.date))
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedSession = session
        } catch {
            print("Failed to create backfill session: \(error)")
        }
    }

    
    var timelineWithMonthStepper: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                MonthStepper(
                    month: selectedMonth,
                    onPrevious: {
                        shiftMonth(by: -1, proxy: proxy)
                    },
                    onNext: {
                        shiftMonth(by: 1, proxy: proxy)
                    },
                    sessions: sessions
                )
                sessionTypeFilterChips.padding(.top, 8)
                
                if (!timelineFilterViewModel.filteredSessions(from: sessions).isEmpty) {
                    timelineList
                } else {
                    PracticeTimelineTypeEmptyState(filter: timelineFilterViewModel.sessionTypeFilter)
                }
                

            }
        }
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
