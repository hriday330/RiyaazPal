//
//  PreviewModelContainer.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-03.
//

import Foundation

import SwiftData

@MainActor
enum PreviewModelContainer {
    static func make() -> ModelContainer {
        try! ModelContainer(
            for: PracticeSession.self,
            configurations: ModelConfiguration(
                isStoredInMemoryOnly: true
            )
        )
    }
}

