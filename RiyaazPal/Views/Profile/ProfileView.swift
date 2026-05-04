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

    @Query(sort: \PracticeAreaEntity.order)
    private var practiceAreas: [PracticeAreaEntity]
    
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            List {
                
                // MARK: Practice Areas Section
                Section {
                    NavigationLink {
                        PracticeAreasPanel()
                    } label: {
                        PracticeAreasRow(areas: practiceAreas)
                    }
                } header: {
                    Text("Practice Areas")
                } footer: {
                    Text("Define the skill areas you'll rate after practice sessions.")
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

private struct PracticeAreasRow: View {
    let areas: [PracticeAreaEntity]

    private var activeAreas: [PracticeAreaEntity] {
        areas.filter(\.isActive)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Practice Areas")
                    .font(.body)
                    .fontWeight(.medium)

                if activeAreas.isEmpty {
                    Text("No areas set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(activeAreas.count) active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "slider.horizontal.3")
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
