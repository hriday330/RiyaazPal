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
    
    @AppStorage("hasCompletedSetup")
    private var hasCompletedSetup: Bool = false


    private var shouldShowSetup: Bool {
        true
    }
    
    var body: some Scene {
        return WindowGroup{
            AppBootstrapView{
                
                if !shouldShowSetup {
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
                } else {
                    SetupView()
                }
                
                
            }
        }
        .modelContainer(for: [
            PracticeSession.self,
            TagCategoryModel.self
        ])
    }
}


struct AppBootstrapView<Content: View>: View {
    @Environment(\.modelContext) private var context
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .task {
                do {
                    try seedDefaultTagCategoriesIfNeeded(context: context)
                } catch {
                    assertionFailure("Failed to seed tag categories: \(error)")
                }
            }
    }
}
