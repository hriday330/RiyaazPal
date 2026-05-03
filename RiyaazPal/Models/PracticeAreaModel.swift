//
//  PracticeAreaModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-05-01.
//

import Foundation
import SwiftData

@Model
final class PracticeAreaEntity {

    @Attribute(.unique) var id: UUID

    var name: String
    var createdAt: Date
    var isActive: Bool
    var order: Int

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        isActive: Bool = true,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.isActive = isActive
        self.order = order
    }
}

@Model
final class PracticeAreaRatingEntity {

    @Attribute(.unique) var id: UUID

    var sessionID: UUID
    var practiceAreaID: UUID
    var score: Int
    var createdAt: Date
    var lastModified: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        practiceAreaID: UUID,
        score: Int,
        createdAt: Date = .now,
        lastModified: Date = .now
    ) {
        self.id = id
        self.sessionID = sessionID
        self.practiceAreaID = practiceAreaID
        self.score = Self.clampedScore(score)
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
}

extension PracticeAreaRatingEntity {
    static let minimumScore = 1
    static let maximumScore = 10

    static func clampedScore(_ score: Int) -> Int {
        min(max(score, minimumScore), maximumScore)
    }
}
