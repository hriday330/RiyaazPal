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
            TabView {
                NavigationStack {
                    PracticeTimelineView()
                }
                .tabItem {
                    Label("Timeline", systemImage: "music.note.list")
                }

                NavigationStack {
                    InsightsView()
                }
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
            }
            
        }
        .modelContainer(for: PracticeSession.self)
    }
}
