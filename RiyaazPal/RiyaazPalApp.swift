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
    
    @StateObject private var tabRouter = TabRouter()
    
    var body: some Scene {
        return WindowGroup{
            AppBootstrapView{
                
                if hasCompletedSetup {
                    RootTabView()
                        .environmentObject(tabRouter)
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

struct RootTabView: View {
    @EnvironmentObject var router: TabRouter
    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                PracticeTimelineView()
            }
            .tabItem {
                Label("Timeline", systemImage: "music.note.list")
            }
            .tag(TabRouter.Tab.timeline)
            
            NavigationStack {
                InsightsView()
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar")
            }
            .tag(TabRouter.Tab.insights)
        }
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

final class TabRouter: ObservableObject {
    @Published var selectedTab: Tab = .timeline

    enum Tab {
        case timeline, insights
    }
}
