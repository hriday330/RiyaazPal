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
    
    @State private var selectedSession: PracticeSession?
    
    @State private var sessionIsInserting: Bool = false
    
    @State private var searchText = ""
    
    @State private var selectedTags: [TagToken] = []
    
    @State private var suggestedTags: [TagToken] = []


    
    var body: some View {
            ZStack {
                // App-wide background
                Color("AppBackground")
                    .ignoresSafeArea()
                if(sessions.isEmpty  && !sessionViewModel.isSessionActive) {
                    emptyState
                } else if isSearching && filteredSessions.isEmpty {
                    filteredEmptyState
                } else {
                    timelineList
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    sessionControl
                }
                
            }
            .navigationTitle("RiyaazPal")
            .searchable(
                text: $searchText,
                tokens: $selectedTags,
                suggestedTokens: $suggestedTags,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search notes or filter by tag",
                token: { token in
                    Text(token.name)
                }
            )
            .onAppear {
                suggestedTags = allTags.map { TagToken(name: $0) }
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
    
    private var allTags: [String] {
        Array(
            Set(sessions.flatMap { $0.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } })
        )
        .sorted()
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedTags.isEmpty
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
            ForEach(timelineViewModel.groupedByDay(from: filteredSessions), id: \.date) { group in
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
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .opacity(0.7)

            VStack(spacing: 6) {
                Text("No practice sessions yet")
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryText"))

                Text("Start a session to track your riyaaz and build a consistent practice habit.")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Group {
                if sessionViewModel.isSessionActive {
                    activeSessionBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button {
                        handleSessionAction()
                    } label: {
                        Label("Start Practice", systemImage: "play.fill")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AccentColor"))
                    .clipShape(Capsule())
                    .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85),
                       value: sessionViewModel.isSessionActive)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
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
    
    var filteredEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("No matching sessions")
                .font(.headline)

            Text("Try a different tag or search term.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredSessions: [PracticeSession] {
        return sessions.filter { session in
            if !selectedTags.isEmpty {
                let selected = Set(selectedTags.map { $0.name.lowercased() })
                let sessionTags = session.tags.map { $0.lowercased() }

                if selected.isDisjoint(with: sessionTags) {
                    return false
                }
            }
            
            if !searchText.isEmpty {
                let text = searchText.lowercased()
                let matches =
                    session.notes.lowercased().contains(text) ||
                    session.detailedNotes.lowercased().contains(text)

                if !matches { return false }
            }
            
            return true
        }
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
