//
//  CategoryDetailView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-19.
//

import Foundation
import SwiftUI

struct CategoryDetailView: View {

    let category: TagCategoryModel

    var body: some View {
        List {
            ForEach(category.tags, id: \.self) { tag in
                Text(tag.capitalized)
            }
        }.toolbar {
            ToolbarItem(placement: .principal) {
                Text(category.name)
                    .font(.title2).fontWeight(.bold)
            }
        }
    }
}
