//
//  CategoryDetailView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-19.
//

import Foundation
import SwiftUI
import SwiftData

struct CategoryDetailView: View {

    let category: TagCategoryModel
    
    @Environment(\.modelContext)
    private var context
    
    @State private var editingTag: String?
    
    var body: some View {
        List {
            ForEach(category.tags, id: \.self) { tag in
                CategoryItemRow(title: tag.capitalized, isEditing: editingTag == tag,
                    onBeginEditing: {
                        editingTag = tag
                    },
                    onCommit: { newName in
                        commitRename(from: tag, to: newName)
                    }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        delete(tag: tag)
                        
                        
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }.toolbar {
            ToolbarItem(placement: .principal) {
                Text(category.name)
                    .font(.title2).fontWeight(.semibold)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    addNewTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
    }
}


private extension CategoryDetailView {
    func delete(tag: String) {
        guard let index = category.tags.firstIndex(of: tag) else { return }
        category.tags.remove(at: index)

        do {
            try context.save()
        } catch {
            print("Failed to delete tag:", error)
        }
    }
    
    

    func addNewTag() {
        let baseName = "New Tag"
        var newTag = baseName
        var counter = 1

        // Ensure uniqueness
        while category.tags.contains(newTag.lowercased()) {
            counter += 1
            newTag = "\(baseName) \(counter)"
        }

        newTag = newTag.lowercased()

        category.tags.insert(newTag, at: 0)

        try? context.save()
        editingTag = newTag
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func commitRename(from old: String, to new: String) {
        guard
            let index = category.tags.firstIndex(of: old),
            !category.tags.contains(new)
        else {
            editingTag = nil
            return
        }

        category.tags[index] = new
        try? context.save()
        editingTag = nil
    }

    

}

#Preview("Category Detail – Sections (Light)") {
    let container = try! ModelContainer(
        for: TagCategoryModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let context = container.mainContext

    let sectionCategory = TagCategoryModel(
        name: "Sections",
        tags: ["alap", "jor", "jhala", "gat"],
        isSystemDefault: true,
        order: 1,
        isFocusRelevant: true
    )

    context.insert(sectionCategory)

    return NavigationStack {
        CategoryDetailView(category: sectionCategory)
    }
    .modelContainer(container)
    .preferredColorScheme(.light)
}
