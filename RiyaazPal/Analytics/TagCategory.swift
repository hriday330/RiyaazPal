//
//  TagCategory.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-07.
//

import Foundation
import SwiftData

// NEW TAG CATEGORY

struct TagCategory: Identifiable, Hashable {
    let id: UUID
    let name: String
    let isFocusRelevant: Bool
}


enum DefaultTagCategories {

    static let all: [TagCategoryModel] = [
        .init(
            name: "Raga",
            tags: [
                "yaman", "puriya", "bhairav", "todi",
                "bhimpalasi", "puriya dhanashri",
                "bilaskhani todi", "ahir bhairav",
                "darbari kanada", "multani"
            ],
            isSystemDefault: true,
            order: 0,
            isFocusRelevant: false
        ),
        .init(
            name: "Section",
            tags: ["alap", "jor", "jhala", "gat"],
            isSystemDefault: true,
            order: 1,
            isFocusRelevant: true
        ),
        .init(
            name: "Technique",
            tags: ["meend", "gamak", "kan", "krintan"],
            isSystemDefault: true,
            order: 2,
            isFocusRelevant: true
        ),
        .init(
            name: "Tempo",
            tags: ["vilambit", "madhya", "drut"],
            isSystemDefault: true,
            order: 3,
            isFocusRelevant: false
        ),
        .init(
            name: "Taal",
            tags: ["teentaal", "jhaptaal", "ektaal", "rupak"],
            isSystemDefault: true,
            order: 4,
            isFocusRelevant: false
        )
    ]
}

func seedDefaultTagCategoriesIfNeeded(context: ModelContext) throws {
    let descriptor = FetchDescriptor<TagCategoryModel>()
    let existing = try context.fetch(descriptor)

    guard existing.isEmpty else { return }

    for category in DefaultTagCategories.all {
        context.insert(category)
    }

    try context.save()
}

final class TagCategorizer {

    private let categories: [TagCategoryModel]

    init(categories: [TagCategoryModel]) {
        self.categories = categories
    }

    func category(for tag: String) -> TagCategory {
        let normalized = tag.lowercased()

        if let match = categories.first(where: {
            $0.tags.contains(normalized)
        }) {
            return TagCategory(id: match.id, name: match.name, isFocusRelevant: match.isFocusRelevant)
        }

        return TagCategory(
            id: UUID(),
            name: "Other",
            isFocusRelevant: false
        )
    }
}
