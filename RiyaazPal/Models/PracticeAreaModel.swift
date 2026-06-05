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

    var id: UUID = UUID()

    var name: String = ""
    var createdAt: Date = Date.now
    var isActive: Bool = true
    var order: Int = 0

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

    var id: UUID = UUID()

    var sessionID: UUID = UUID()
    var practiceAreaID: UUID = UUID()
    var areaName: String = ""
    var didPractice: Bool = false
    var score: Int? = nil
    var createdAt: Date = Date.now
    var lastModified: Date = Date.now

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        practiceAreaID: UUID,
        areaName: String,
        didPractice: Bool,
        score: Int?,
        createdAt: Date = .now,
        lastModified: Date = .now
    ) {
        self.id = id
        self.sessionID = sessionID
        self.practiceAreaID = practiceAreaID
        self.areaName = areaName
        self.didPractice = didPractice
        self.score = didPractice ? score.map(Self.clampedScore) : nil
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
