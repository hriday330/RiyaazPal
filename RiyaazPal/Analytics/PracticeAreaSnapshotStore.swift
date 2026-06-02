//
//  PracticeAreaSnapshotStore.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-06-02.
//

import Foundation
import SwiftData

struct PracticeAreaSnapshot: Codable, Equatable {
    let id: UUID
    let name: String
    let createdAt: Date
    let isActive: Bool
    let order: Int
    let lastModified: Date
}

enum PracticeAreaSnapshotStore {
    private static let snapshotsKey = "practiceAreaSnapshots.v1"
    private static let store = NSUbiquitousKeyValueStore.default

    @discardableResult
    static func synchronize() -> Bool {
        store.synchronize()
    }

    static func snapshots() -> [PracticeAreaSnapshot] {
        synchronize()

        guard let data = store.data(forKey: snapshotsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([PracticeAreaSnapshot].self, from: data)
        } catch {
            print("PracticeAreaSnapshotStore.snapshots decode error:", error)
            return []
        }
    }

    @MainActor
    static func save(areas: [PracticeAreaEntity]) {
        let snapshots = areas.map(PracticeAreaSnapshot.init(area:))

        do {
            let data = try JSONEncoder().encode(snapshots)
            store.set(data, forKey: snapshotsKey)
            synchronize()
        } catch {
            print("PracticeAreaSnapshotStore.save encode error:", error)
        }
    }

    @MainActor
    @discardableResult
    static func restoreInto(
        context: ModelContext,
        existingAreas: [PracticeAreaEntity]
    ) -> Bool {
        let incomingSnapshots = snapshots()

        guard !incomingSnapshots.isEmpty else {
            return false
        }

        var didChangeLocalStore = false
        let existingAreasByID = newestAreasByID(from: existingAreas)

        for snapshot in incomingSnapshots {
            if let area = existingAreasByID[snapshot.id] {
                guard snapshot.lastModified > area.lastModified else {
                    continue
                }

                snapshot.apply(to: area)
                didChangeLocalStore = true
            } else {
                context.insert(PracticeAreaEntity(snapshot: snapshot))
                didChangeLocalStore = true
            }
        }

        if didChangeLocalStore {
            do {
                try context.save()
            } catch {
                print("PracticeAreaSnapshotStore.restore save error:", error)
                return false
            }
        }

        if !existingAreas.isEmpty {
            save(areas: existingAreas)
        }

        return didChangeLocalStore
    }

    @MainActor
    private static func newestAreasByID(
        from areas: [PracticeAreaEntity]
    ) -> [UUID: PracticeAreaEntity] {
        areas.reduce(into: [:]) { partialResult, area in
            guard let existingArea = partialResult[area.id] else {
                partialResult[area.id] = area
                return
            }

            if area.lastModified > existingArea.lastModified {
                partialResult[area.id] = area
            }
        }
    }
}

private extension PracticeAreaSnapshot {
    init(area: PracticeAreaEntity) {
        self.id = area.id
        self.name = area.name
        self.createdAt = area.createdAt
        self.isActive = area.isActive
        self.order = area.order
        self.lastModified = area.lastModified
    }

    func apply(to area: PracticeAreaEntity) {
        area.name = name
        area.createdAt = createdAt
        area.isActive = isActive
        area.order = order
        area.lastModified = lastModified
    }
}

private extension PracticeAreaEntity {
    convenience init(snapshot: PracticeAreaSnapshot) {
        self.init(
            id: snapshot.id,
            name: snapshot.name,
            createdAt: snapshot.createdAt,
            isActive: snapshot.isActive,
            order: snapshot.order,
            lastModified: snapshot.lastModified
        )
    }
}
