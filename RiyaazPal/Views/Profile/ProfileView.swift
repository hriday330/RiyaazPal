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
    
    @Environment(\.dismiss) 
    private var dismiss


    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            List {
                ForEach(categories) { category in
                    NavigationLink {
                        CategoryDetailView(category: category)
                    } label: {
                        ProfileCategoryRow(category: category)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Practice Setup")
                    .font(.title2).fontWeight(.bold)
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


