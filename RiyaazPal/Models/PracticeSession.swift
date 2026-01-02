//
//  PracticeSession.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-31.
//

import Foundation

struct PracticeSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let duration: TimeInterval
    var notes: String
    var tags: [String]

    init(
        id: UUID = UUID(),
        startTime: Date,
        duration: TimeInterval,
        notes: String,
        tags: [String] = []
    ) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.notes = notes
        self.tags = tags
    }
}

