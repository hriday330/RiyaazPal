//
//  EditSessionViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-16.
//

import Foundation
import SwiftUI
import Combine

final class EditSessionViewModel: ObservableObject {

    let session: PracticeSession

    @Published var draft: PracticeSessionDraft
    @Published var newTag: String = ""

    @Published var showingDurationPicker = false
    @Published var showingStartTimePicker = false

    @Published var suggestedTags: [String] = []

    private var tagProvider: CategoryTagProvider?
    private var cancellables = Set<AnyCancellable>()
    private let suggestionTrigger = PassthroughSubject<Void, Never>()


    init(session: PracticeSession) {
        self.session = session
        self.draft = PracticeSessionDraft(
            id: session.id,
            startTime: session.startTime,
            duration: session.duration,
            notes: session.notes,
            tags: session.tags,
            detailedNotes: session.detailedNotes,
            sessionType: session.resolvedSessionType
            
        )
        setupSuggestionDebounce()
    }
}

extension EditSessionViewModel {

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: draft.startTime)
    }

    var durationMinutes: Int {
        get { Int(draft.duration / 60) }
        set { draft.duration = TimeInterval(newValue * 60) }
    }

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60

        if hours > 0 {
            return minutes > 0
                ? "\(hours) hr \(minutes) min"
                : "\(hours) hr"
        } else {
            return "\(minutes) min"
        }
    }
}

extension EditSessionViewModel {

    func addTag() {
        let normalized = normalizeTag(newTag)
        guard !normalized.isEmpty else { return }

        let exists = draft.tags
            .map(normalizeTag)
            .contains(normalized)

        guard !exists else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        draft.tags.append(
            newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        newTag = ""
    }

    func commit() {
        session.notes = draft.notes
        session.tags = draft.tags
        session.detailedNotes = draft.detailedNotes
        session.duration = draft.duration
        session.startTime = draft.startTime
        session.lastModified = .now
        session.sessionType = draft.sessionType
    }

    private func normalizeTag(_ tag: String) -> String {
        tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension EditSessionViewModel {

    private static let suggester = TagSuggester()

    func configureTagSource(categories: [TagCategoryModel]) {
        self.tagProvider = CategoryTagProvider(categories: categories)
        computeSuggestions()
    }

    func computeSuggestions() {
        guard let tagProvider else { return }

        suggestedTags = Self.suggester.suggestions(
            title: draft.notes,
            details: draft.detailedNotes,
            existingTags: draft.tags,
            candidateTags: tagProvider.allTags()
        )
    }
    
    func addSuggestedTag(_ tag: String) {
        let normalized = normalizeTag(tag)

        let exists = draft.tags
            .map(normalizeTag)
            .contains(normalized)

        guard !exists else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        draft.tags.append(tag)
        computeSuggestions()
    }

    // MARK: - Hooks from editing

    func updateNotes(_ text: String) {
        draft.notes = text
        suggestionTrigger.send()
    }

    func updateDetailedNotes(_ text: String) {
        draft.detailedNotes = text
        suggestionTrigger.send()
    }
    
    private func setupSuggestionDebounce() {
        suggestionTrigger
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.computeSuggestions()
            }
            .store(in: &cancellables)
    }
    
}

struct PracticeSessionDraft {
    let id: UUID
    var startTime: Date
    var duration: TimeInterval
    var notes: String
    var tags: [String]
    var detailedNotes: String
    var sessionType: SessionType = .practice
}
