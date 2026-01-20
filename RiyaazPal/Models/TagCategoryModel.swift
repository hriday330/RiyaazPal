//
//  TagCategoryModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-19.
//

import Foundation
import SwiftData

@Model
final class TagCategoryModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var tags: [String]
    var isSystemDefault: Bool
    var order: Int
    var isFocusRelevant: Bool

    init(
        id: UUID = UUID(),
        name: String,
        tags: [String],
        isSystemDefault: Bool,
        order: Int,
        isFocusRelevant: Bool
    ) {
        self.id = id
        self.name = name
        self.tags = tags
        self.isSystemDefault = isSystemDefault
        self.order = order
        self.isFocusRelevant = isFocusRelevant
    }
}
