//
//  TagCategory.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-07.
//

import Foundation

enum TagCategory {
    case raga
    case section
    case technique
    case tempo
    case other
}

struct TagRegistry {

    private static let ragas: Set<String> = [
        "yaman", "puriya", "bhairav", "todi", "bhimpalasi", "puriya dhanashri", "bilaskhani todi", "ahir bhairav", "darbari kanada", "multani"
    ]

    private static let sections: Set<String> = [
        "alap", "jor", "jhala", "gat",
    ]

    private static let techniques: Set<String> = [
        "meend", "gamak", "kan", "krintan", 
    ]

    private static let tempos: Set<String> = [
        "vilambit", "madhya", "drut"
    ]
    
    private static let taal: Set<String> = [
        "teentaal", "jhaptaal", "ektaal", "rupak"
    ]

    static func category(for tag: String) -> TagCategory {
        if sections.contains(tag) { return .section }
        if techniques.contains(tag) { return .technique }
        if tempos.contains(tag) { return .tempo }
        if ragas.contains(tag) { return .raga }
        return .other
    }
}
