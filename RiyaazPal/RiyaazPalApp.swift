//
//  RiyaazPalApp.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2025-12-29.
//

import SwiftUI
import SwiftData

@main
struct RiyaazPalApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PracticeTimelineView()
            }
            
        }
        .modelContainer(for: PracticeSession.self)
    }
}
