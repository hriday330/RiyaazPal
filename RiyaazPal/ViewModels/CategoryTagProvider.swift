//
//  CategoryTagProvider.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-25.
//

import Foundation


struct CategoryTagProvider {

    let categories: [TagCategoryModel]

    func allTags() -> [String] {
        categories
            .flatMap { $0.tags }
            .uniqued()
    }
}

private extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        Array(Set(self))
    }
}
