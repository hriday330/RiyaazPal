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

    @Attribute(.unique) var id: UUID

    var type: GoalTypeRaw
    var tagID: UUID
    var displayName: String

    var intent: GoalIntentRaw?

    var createdAt: Date
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        type: GoalTypeRaw,
        tagID: UUID,
        displayName: String,
        intent: GoalIntentRaw? = nil,
        createdAt: Date = .now,
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.tagID = tagID
        self.displayName = displayName
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
