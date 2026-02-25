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
        candidateTags: [String]
    ) -> [String] {

        let text = (title + " " + details).lowercased()

        let tokens = text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        return candidateTags
            .filter { tag in
                let tagLower = tag.lowercased()

                // do not suggest already-selected tags
                if existingTags.contains(where: {
                    $0.caseInsensitiveCompare(tag) == .orderedSame
                }) {
                    return false
                }

                return tokens.contains { token in
                    tagLower.contains(token) || token.contains(tagLower)
                }
            }
            .sorted()
    }
}
