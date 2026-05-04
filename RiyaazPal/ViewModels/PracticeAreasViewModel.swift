//
//  PracticeAreasViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-05-03.
//

import Foundation
import SwiftData
import SwiftUI

final class PracticeAreasViewModel: ObservableObject {

    @Published var showDuplicateAlert = false
    @Published var showEmptyNameAlert = false

    private var context: ModelContext?

    func attachContext(_ context: ModelContext) {
        self.context = context
    }

    @MainActor
    func createArea(
        name: String,
        currentAreas: [PracticeAreaEntity]
    ) -> PracticeAreaEntity? {
        guard let context else { return nil }

        let trimmed = normalizedDisplayName(name)

        guard !trimmed.isEmpty else {
            showEmptyNameAlert = true
            return nil
        }

        guard !containsActiveDuplicate(
            name: trimmed,
            currentAreas: currentAreas
        ) else {
            showDuplicateAlert = true
            return nil
        }

        let nextOrder = (currentAreas.map(\.order).max() ?? -1) + 1
        let area = PracticeAreaEntity(
            name: trimmed,
            order: nextOrder
        )

        context.insert(area)

        do {
            try context.save()
            return area
        } catch {
            print("PracticeAreasViewModel.createArea error:", error)
            return nil
        }
    }

    @MainActor
    func renameArea(
        _ area: PracticeAreaEntity,
        to name: String,
        currentAreas: [PracticeAreaEntity]
    ) -> Bool {
        guard let context else { return false }

        let trimmed = normalizedDisplayName(name)

        guard !trimmed.isEmpty else {
            showEmptyNameAlert = true
            return false
        }

        guard !containsActiveDuplicate(
            name: trimmed,
            currentAreas: currentAreas,
            excluding: area.id
        ) else {
            showDuplicateAlert = true
            return false
        }

        area.name = trimmed

        do {
            try context.save()
            return true
        } catch {
            print("PracticeAreasViewModel.renameArea error:", error)
            return false
        }
    }

    @MainActor
    func deactivateArea(_ area: PracticeAreaEntity) {
        guard let context else { return }

        area.isActive = false

        do {
            try context.save()
        } catch {
            print("PracticeAreasViewModel.deactivateArea error:", error)
        }
    }

    @MainActor
    func moveAreas(
        from source: IndexSet,
        to destination: Int,
        activeAreas: [PracticeAreaEntity]
    ) {
        guard let context else { return }

        var reordered = activeAreas
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, area) in reordered.enumerated() {
            area.order = index
        }

        do {
            try context.save()
        } catch {
            print("PracticeAreasViewModel.moveAreas error:", error)
        }
    }
}

private extension PracticeAreasViewModel {

    func normalizedDisplayName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func containsActiveDuplicate(
        name: String,
        currentAreas: [PracticeAreaEntity],
        excluding id: UUID? = nil
    ) -> Bool {
        currentAreas.contains { area in
            area.isActive &&
            area.id != id &&
            area.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }
}
