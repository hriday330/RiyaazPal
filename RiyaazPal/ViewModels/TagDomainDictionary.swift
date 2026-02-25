//
//  TagDomainDictionary.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-25.
//

import Foundation

enum TagDomainDictionary {

    static let ragas: [String] = [
        "Yaman", "Bhairav", "Darbari", "Todi", "Bageshree", "Multani"
    ]

    static let techniques: [String] = [
        "Meend", "Gamaka", "Tan", "Alap", "Jor", "Jhala"
    ]

    static let forms: [String] = [
        "Bandish", "Tarana", "Sargam", "Vilambit", "Drut"
    ]

    static var all: [String] {
        Array(Set(ragas + techniques + forms))
    }
}
