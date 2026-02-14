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
    var sessionType: SessionType?

    var resolvedSessionType: SessionType {
        sessionType ?? .practice
    }
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        duration: TimeInterval,
        notes: String,
        tags: [String] = [],
        detailedNotes: String = "",
        lastModified: Date = .now,
        sessionType: SessionType = .practice
    ) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.notes = notes
        self.tags = tags
        self.detailedNotes = detailedNotes
        self.lastModified = lastModified
        self.sessionType = sessionType
        
    }
}

