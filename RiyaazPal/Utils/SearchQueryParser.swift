//
//  parseSearchQuery.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-05.
//

import Foundation

struct SearchQuery {
    let tag: String?
    let text: String
}

enum SearchQueryParser {
    static func parse(_ input: String) -> SearchQuery {
        let tokens = input
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        var tag: String?
        var textParts: [String] = []

        for token in tokens {
            if token.hasPrefix("#"), tag == nil {
                let rawTag = String(token.dropFirst())
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !rawTag.isEmpty {
                    tag = rawTag.lowercased()
                }
            } else {
                textParts.append(token)
            }
        }

        return SearchQuery(
            tag: tag,
            text: textParts.joined(separator: " ").lowercased()
        )
    }
}
