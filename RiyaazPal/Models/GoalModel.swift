//
//  GoalModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-16.
//

import Foundation
import SwiftData

@Model
final class GoalEntity {

    var id: UUID = UUID()

    var type: GoalTypeRaw = GoalTypeRaw.raga

    var categoryID: UUID = UUID()
    var tagName: String = ""

    var intent: GoalIntentRaw? = nil

    var createdAt: Date = Date.now
    var isActive: Bool = true

    init(
        id: UUID = UUID(),
        type: GoalTypeRaw,
        categoryID: UUID,
        tagName: String,
        intent: GoalIntentRaw? = nil,
        createdAt: Date = .now,
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.categoryID = categoryID
        self.tagName = tagName
        self.intent = intent
        self.createdAt = createdAt
        self.isActive = isActive
    }
}


enum GoalTypeRaw: String, Codable {
    case raga
    case technique
}

enum GoalIntentRaw: String, Codable {
    case deepenExploration
    case increaseComfort
    case stabilize
    case improveClarity
    case increaseComplexity
    case buildStamina
}
