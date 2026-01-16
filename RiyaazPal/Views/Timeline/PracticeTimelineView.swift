//
//  PracticeTimelineView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-29.
//

import SwiftUI
import SwiftData

// TODO - extract subviews
struct PracticeTimelineView: View {
    
    @Query(sort: \PracticeSession.startTime, order: .reverse)
        private var sessions: [PracticeSession]
    
    @StateObject private var timelineViewModel = PracticeTimelineViewModel()
    
    @Environment(\.modelContext)
    private var context
    
    @StateObject private var sessionViewModel = PracticeSessionViewModel()
    
    @StateObject private var timelineFilterViewModel = TimelineFilterViewModel();
    
    @State private var selectedSession: PracticeSession?

    var body: some View {
            ZStack {
                // App-wide background
                Color("AppBackground")
                    .ignoresSafeArea()
                if(sessions.isEmpty  && !sessionViewModel.isSessionActive) {
                    PracticeTimelineEmptyState(isSessionActive: sessionViewModel.isSessionActive, onStartSession: handleSessionAction) {
                        activeSessionBar
                    }
                } else if timelineFilterViewModel.isSearching && timelineFilterViewModel.filteredSessions(from: sessions).isEmpty {
                    PracticeTimelineFilteredEmptyState()
                } else {
                    timelineList
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    sessionControl
                }
                
            }
            .navigationTitle("RiyaazPal")
            .searchable(
                text: $timelineFilterViewModel.searchText,
                tokens: $timelineFilterViewModel.selectedTags,
                suggestedTokens: .constant(timelineFilterViewModel.suggestedTags(from: sessions)),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search notes or filter by tag",
                token: { token in
                    Text(token.name)
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
    
    
    var formattedElapsedTime: String {
        let minutes = Int(sessionViewModel.elapsedTime) / 60
        let seconds = Int(sessionViewModel.elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    
    var sessionControl: some View {
        Group {
            if sessionViewModel.isSessionActive {
                activeSessionBar
            } else {
                floatingSessionButton
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
                }
            }
        }
    }
    
    var floatingSessionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    handleSessionAction()
                } label : {
                    Label(
                        sessionViewModel.isSessionActive ? "End Session" : "Start Session",
                        systemImage: sessionViewModel.isSessionActive ? "stop.fill" : "play.fill"
                    )
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentColor"))
                .clipShape(Capsule())
                .shadow(radius: 8)
                .padding()
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: sessionViewModel.isSessionActive)
            }
        }
    }
    
    var activeSessionBar: some View {
        VStack {
            Spacer()

            Button {
                handleSessionAction()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(Color("AccentColor"))

                    Text(formattedElapsedTime)
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryText"))

                    Spacer()

                    Text("Recording")
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("ActiveCardBackground"))
                )
                .shadow(radius: 6)
                .padding(.horizontal)
                .padding(.bottom, 12)
                .ignoresSafeArea()
            }
        }.transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct TagToken: Identifiable, Hashable {
    var id: String { name }
    let name: String
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
