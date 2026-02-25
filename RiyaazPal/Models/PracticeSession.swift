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
    // confidence level 1-10 (only used for concerts)
    var confidence: Int?

    var resolvedSessionType: SessionType {
        sessionType ?? .practice
    }
    
    var resolvedConfidence: Int? {
        guard resolvedSessionType == .concert,
              let confidence else { return nil }

        return min(max(confidence, 1), 10)
    }
    
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        duration: TimeInterval,
        notes: String,
        tags: [String] = [],
        detailedNotes: String = "",
        lastModified: Date = .now,
        sessionType: SessionType = .practice,
        confidence: Int = 5
    ) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.notes = notes
        self.tags = tags
        self.detailedNotes = detailedNotes
        self.lastModified = lastModified
        self.sessionType = sessionType
        self.confidence = confidence
        
    }
}

