//
//  TimelineFilterViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-15.
//

import Foundation
import SwiftUI

final class TimelineFilterViewModel: ObservableObject {

    @Published var searchText = ""
    @Published var selectedTags: [TagToken] = []
    @Published var highlightedTag: String?

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !selectedTags.isEmpty
    }

    func suggestedTags(from sessions: [PracticeSession]) -> [TagToken] {
        let tags = Set(
            sessions.flatMap {
                $0.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
        )
        return tags.sorted().map { TagToken(name: $0) }
    }

    func filteredSessions(
        from sessions: [PracticeSession]
    ) -> [PracticeSession] {

        sessions.filter { session in
            if !selectedTags.isEmpty {
                let selected = Set(selectedTags.map { $0.name.lowercased() })
                let sessionTags = session.tags.map { $0.lowercased() }

                if !selected.isSubset(of: sessionTags) {
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

    func handleSearchSubmit() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !selectedTags.contains(where: {
            $0.name.caseInsensitiveCompare(trimmed) == .orderedSame
        }) {
            selectedTags.append(TagToken(name: trimmed))
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                highlightedTag = trimmed
            }
        }

        UISelectionFeedbackGenerator().selectionChanged()
        searchText = ""
    }
}
