//
//  TagSuggester.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-25.
//

import Foundation

struct TagSuggester {

    func suggestions(
        title: String,
        details: String,
        existingTags: [String],
        sessions: [PracticeSession],
        excludingSessionID: UUID,
        limit: Int = 6,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [String] {
        let text = (title + " " + details).lowercased()
        let textTokens = Self.tokens(from: text)
        let existingNormalizedTags = Set(existingTags.map(Self.normalizedTag))

        var candidates: [String: TagSuggestionCandidate] = [:]

        for session in sessions where session.id != excludingSessionID {
            for rawTag in session.tags {
                let displayTag = rawTag.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalizedTag = Self.normalizedTag(displayTag)

                guard !normalizedTag.isEmpty else { continue }
                guard !existingNormalizedTags.contains(normalizedTag) else { continue }

                var candidate = candidates[normalizedTag] ?? TagSuggestionCandidate(
                    displayTag: displayTag,
                    frequency: 0,
                    latestUse: session.startTime
                )

                candidate.frequency += 1
                candidate.latestUse = max(candidate.latestUse, session.startTime)

                if displayTag.count < candidate.displayTag.count {
                    candidate.displayTag = displayTag
                }

                candidates[normalizedTag] = candidate
            }
        }

        return candidates.values
            .sorted {
                let lhsScore = score(
                    candidate: $0,
                    textTokens: textTokens,
                    now: now,
                    calendar: calendar
                )
                let rhsScore = score(
                    candidate: $1,
                    textTokens: textTokens,
                    now: now,
                    calendar: calendar
                )

                if lhsScore == rhsScore {
                    return $0.displayTag.localizedCaseInsensitiveCompare($1.displayTag) == .orderedAscending
                }

                return lhsScore > rhsScore
            }
            .prefix(limit)
            .map(\.displayTag)
    }
}

private extension TagSuggester {
    struct TagSuggestionCandidate {
        var displayTag: String
        var frequency: Int
        var latestUse: Date
    }

    static func normalizedTag(_ tag: String) -> String {
        tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func tokens(from text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { $0.count >= 2 }
    }

    func score(
        candidate: TagSuggestionCandidate,
        textTokens: [String],
        now: Date,
        calendar: Calendar
    ) -> Int {
        var score = min(candidate.frequency, 5) * 3

        if matchesText(candidate.displayTag, textTokens: textTokens) {
            score += 20
        }

        let daysSinceUse = max(
            0,
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: candidate.latestUse),
                to: calendar.startOfDay(for: now)
            ).day ?? 0
        )

        switch daysSinceUse {
        case 0...7:
            score += 8
        case 8...30:
            score += 5
        case 31...90:
            score += 2
        default:
            break
        }

        return score
    }

    func matchesText(
        _ tag: String,
        textTokens: [String]
    ) -> Bool {
        let tagTokens = Self.tokens(from: tag)
        let normalizedTag = Self.normalizedTag(tag)

        return textTokens.contains { token in
            normalizedTag.contains(token)
            || tagTokens.contains { tagToken in
                token.contains(tagToken) || tagToken.contains(token)
            }
        }
    }
}
