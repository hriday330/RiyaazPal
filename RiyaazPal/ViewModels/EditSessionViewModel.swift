//
//  EditSessionViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-16.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

final class EditSessionViewModel: ObservableObject {

    let session: PracticeSession

    @Published var draft: PracticeSessionDraft
    @Published var newTag: String = ""

    @Published var showingDurationPicker = false
    @Published var showingStartTimePicker = false

    @Published var suggestedTags: [String] = []
    @Published var practiceAreaDrafts: [PracticeAreaQuestionnaireDraft] = []
    @Published var hasPracticeAreaReflection = false

    private var tagSuggestionSessions: [PracticeSession] = []
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
            sessionType: session.resolvedSessionType,
            confidence: session.resolvedConfidence
            
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

    func commit() -> Bool {
        var didChange = false

        if session.notes != draft.notes {
            session.notes = draft.notes
            didChange = true
        }

        if session.tags != draft.tags {
            session.tags = draft.tags
            didChange = true
        }

        if session.detailedNotes != draft.detailedNotes {
            session.detailedNotes = draft.detailedNotes
            didChange = true
        }

        if session.duration != draft.duration {
            session.duration = draft.duration
            didChange = true
        }

        if session.startTime != draft.startTime {
            session.startTime = draft.startTime
            didChange = true
        }

        if session.resolvedSessionType != draft.sessionType {
            session.sessionType = draft.sessionType
            didChange = true
        }

        if session.confidence != draft.confidence {
            session.confidence = draft.confidence
            didChange = true
        }

        if didChange {
            session.lastModified = .now
        }

        return didChange
    }

    func commitPracticeAreaRatings(
        context: ModelContext,
        existingRatings: [PracticeAreaRatingEntity]
    ) -> Bool {
        guard hasPracticeAreaReflection else { return false }

        var didChange = false
        let now = Date.now

        let ratingsByAreaID = Dictionary(
            existingRatings.map { ($0.practiceAreaID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let ratingsByAreaName = Dictionary(
            existingRatings.map { (Self.normalizedAreaName($0.areaName), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        for draft in practiceAreaDrafts {
            let existingRating = ratingsByAreaID[draft.practiceAreaID]
                ?? ratingsByAreaName[Self.normalizedAreaName(draft.areaName)]

            if let rating = existingRating {
                let score = draft.didPractice ? draft.score.map(PracticeAreaRatingEntity.clampedScore) : nil
                var didUpdateRating = false

                if rating.practiceAreaID != draft.practiceAreaID {
                    rating.practiceAreaID = draft.practiceAreaID
                    didUpdateRating = true
                }

                if rating.areaName != draft.areaName {
                    rating.areaName = draft.areaName
                    didUpdateRating = true
                }

                if rating.didPractice != draft.didPractice {
                    rating.didPractice = draft.didPractice
                    didUpdateRating = true
                }

                if rating.score != score {
                    rating.score = score
                    didUpdateRating = true
                }

                if didUpdateRating {
                    rating.lastModified = now
                    didChange = true
                }
            } else {
                let rating = PracticeAreaRatingEntity(
                    sessionID: draft.sessionID,
                    practiceAreaID: draft.practiceAreaID,
                    areaName: draft.areaName,
                    didPractice: draft.didPractice,
                    score: draft.score
                )
                context.insert(rating)
                didChange = true
            }
        }

        return didChange
    }

    private func normalizeTag(_ tag: String) -> String {
        tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension EditSessionViewModel {

    private static let suggester = TagSuggester()

    func configureTagSource(sessions: [PracticeSession]) {
        self.tagSuggestionSessions = sessions
        computeSuggestions()
    }

    func computeSuggestions() {
        suggestedTags = Self.suggester.suggestions(
            title: draft.notes,
            details: draft.detailedNotes,
            existingTags: draft.tags,
            sessions: tagSuggestionSessions,
            excludingSessionID: draft.id
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

extension EditSessionViewModel {

    func configurePracticeAreaQuestionnaire(
        practiceAreas: [PracticeAreaEntity],
        existingRatings: [PracticeAreaRatingEntity]
    ) {
        let existingByAreaID = Dictionary(
            existingRatings.map { ($0.practiceAreaID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let existingByAreaName = Dictionary(
            existingRatings.map { (Self.normalizedAreaName($0.areaName), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let activeAreas = practiceAreas
            .filter(\.isActive)
            .sorted { $0.order < $1.order }

        let activeDrafts = activeAreas.map { area in
            let existing = existingByAreaID[area.id]
                ?? existingByAreaName[Self.normalizedAreaName(area.name)]

            if let existing {
                return PracticeAreaQuestionnaireDraft(
                    sessionID: session.id,
                    practiceAreaID: area.id,
                    areaName: area.name,
                    didPractice: existing.didPractice,
                    score: existing.score
                )
            }

            return PracticeAreaQuestionnaireDraft(
                sessionID: session.id,
                practiceAreaID: area.id,
                areaName: area.name,
                didPractice: false,
                score: nil
            )
        }

        let activeAreaIDs = Set(activeAreas.map(\.id))
        let activeAreaNames = Set(activeAreas.map { Self.normalizedAreaName($0.name) })
        let historicalDrafts = existingRatings
            .filter {
                !activeAreaIDs.contains($0.practiceAreaID) &&
                !activeAreaNames.contains(Self.normalizedAreaName($0.areaName))
            }
            .map { rating in
                PracticeAreaQuestionnaireDraft(
                    sessionID: session.id,
                    practiceAreaID: rating.practiceAreaID,
                    areaName: rating.areaName,
                    didPractice: rating.didPractice,
                    score: rating.score
                )
            }

        practiceAreaDrafts = activeDrafts + historicalDrafts
        hasPracticeAreaReflection = !existingRatings.isEmpty
    }

    func markPracticeAreaReflectionStarted() {
        hasPracticeAreaReflection = true
    }

    func repeatPracticeAreaReflection(
        from previousRatings: [PracticeAreaRatingEntity]
    ) {
        let previousByAreaID = Dictionary(
            previousRatings.map { ($0.practiceAreaID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let previousByAreaName = Dictionary(
            previousRatings.map { (Self.normalizedAreaName($0.areaName), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        practiceAreaDrafts = practiceAreaDrafts.map { draft in
            guard let previousRating = previousByAreaID[draft.practiceAreaID]
                    ?? previousByAreaName[Self.normalizedAreaName(draft.areaName)]
            else { return draft }

            return PracticeAreaQuestionnaireDraft(
                sessionID: draft.sessionID,
                practiceAreaID: draft.practiceAreaID,
                areaName: draft.areaName,
                didPractice: previousRating.didPractice,
                score: previousRating.score
            )
        }

        hasPracticeAreaReflection = true
    }

    func appendPracticeAreaDraft(for area: PracticeAreaEntity) {
        let normalizedName = Self.normalizedAreaName(area.name)

        guard !practiceAreaDrafts.contains(where: {
            $0.practiceAreaID == area.id ||
            Self.normalizedAreaName($0.areaName) == normalizedName
        }) else {
            return
        }

        practiceAreaDrafts.append(
            PracticeAreaQuestionnaireDraft(
                sessionID: session.id,
                practiceAreaID: area.id,
                areaName: area.name,
                didPractice: false,
                score: nil
            )
        )
        hasPracticeAreaReflection = true
    }

    func updatePracticeAreaScore(
        for draftID: UUID,
        score: Int
    ) {
        guard let index = practiceAreaDrafts.firstIndex(where: { $0.id == draftID }) else {
            return
        }

        practiceAreaDrafts[index].didPractice = true
        practiceAreaDrafts[index].score = PracticeAreaRatingEntity.clampedScore(score)
        hasPracticeAreaReflection = true
    }

    func markPracticeAreaNotPracticed(
        draftID: UUID
    ) {
        guard let index = practiceAreaDrafts.firstIndex(where: { $0.id == draftID }) else {
            return
        }

        practiceAreaDrafts[index].didPractice = false
        practiceAreaDrafts[index].score = nil
        hasPracticeAreaReflection = true
    }

    var practicedAreaCount: Int {
        practiceAreaDrafts.filter(\.didPractice).count
    }

    static func normalizedAreaName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
    var confidence: Int?
    // for slider binding
    var resolvedConfidence: Int {
        get { min(max(confidence ?? 5, 1), 10) }
        set { confidence = min(max(newValue, 1), 10) }
    }
}

struct PracticeAreaQuestionnaireDraft: Identifiable, Hashable {
    var id: UUID { practiceAreaID }

    let sessionID: UUID
    let practiceAreaID: UUID
    var areaName: String
    var didPractice: Bool
    var score: Int?

    var resolvedScore: Int {
        score ?? 5
    }
}
