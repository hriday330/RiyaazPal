//
//  PracticeSession.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-31.
//

import Foundation
import SwiftData

@Model
final class PracticeSession {
    let id: UUID
    var startTime: Date
    var duration: TimeInterval
    var notes: String
    var tags: [String]
    var detailedNotes: String
    var lastModified: Date

    init(
        id: UUID = UUID(),
        startTime: Date,
        duration: TimeInterval,
        notes: String,
        tags: [String] = [],
        detailedNotes: String = "",
        lastModified: Date = .now
    ) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.notes = notes
        self.tags = tags
        self.detailedNotes = detailedNotes
        self.lastModified = lastModified
    }
}

