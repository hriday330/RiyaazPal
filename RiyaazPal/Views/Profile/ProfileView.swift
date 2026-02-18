//
//  ProfileView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-19.
//

import Foundation

import SwiftUI
import SwiftData

struct ProfileView: View {

    @Query(sort: \TagCategoryModel.order)
    private var categories: [TagCategoryModel]
    
    @Query(filter: #Predicate<GoalEntity> { $0.isActive == true })
    private var activeGoals: [GoalEntity]
    
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            List {
                
                // MARK: Goals Section
                Section {
                    NavigationLink {
                        GoalsPanel(goals: activeGoals)
                    } label: {
                        GoalsRow(goals: activeGoals)
                    }
                } header: {
                    Text("Goals")
                } footer: {
                    Text("Define what you're actively working toward in your riyaz.")
                }

                // MARK: Practice Setup Section
                Section {
                    ForEach(categories) { category in
                        NavigationLink {
                            CategoryDetailView(category: category)
                        } label: {
                            ProfileCategoryRow(category: category)
                        }
                    }
                } header: {
                    Text("Practice Setup")
                } footer: {
                    Text("Customize ragas, sections, taals, and techniques.")
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                }
                .accessibilityLabel("Close")
            }
        }
    }
}

private struct GoalsRow: View {
    let goals: [GoalEntity]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Goals")
                    .font(.body)
                    .fontWeight(.medium)

                if goals.isEmpty {
                    Text("No goals set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(goals.count) active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "target")
                .foregroundStyle(Color("AccentColor"))
        }
        .padding(.vertical, 4)
    }
}


private struct ProfileCategoryRow: View {
    let category: TagCategoryModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text("\(category.tags.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview("Profile – Light") {
    let container = PreviewModelContainer.make()

    return NavigationStack {
        ProfileView()
    }
    .modelContainer(container)
    .preferredColorScheme(.light)
}

#Preview("Profile – Dark") {
    let container = PreviewModelContainer.make()

    return NavigationStack {
        ProfileView()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
