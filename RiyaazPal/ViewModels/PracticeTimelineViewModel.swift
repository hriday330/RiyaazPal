//
//  PracticeTimelineViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-31.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class PracticeTimelineViewModel: ObservableObject {

    func groupedByDay(
            from sessions: [PracticeSession]
        ) -> [(date: Date, sessions: [PracticeSession])] {

            let grouped = Dictionary(grouping: sessions) {
                Calendar.current.startOfDay(for: $0.startTime)
            }

            return grouped
                .sorted { $0.key > $1.key }
                .map { (date: $0.key, sessions: $0.value) }
        }

    

}

