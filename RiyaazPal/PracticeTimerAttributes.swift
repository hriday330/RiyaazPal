//
//  PracticeTimerAttributes.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-03-04.
//

import Foundation
import ActivityKit

struct PracticeTimerActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        var startTime: Date
    }
    var title: String
}
