// AddAllBadges.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct AddAllBadges: AsyncMigration {
    func prepare(on database: Database) async throws {
        let badges = getAllBadges()
        try await saveAllBadges(badges, database: database)
    }

    func revert(on database: Database) async throws {
        try await deleteAllBadges(database: database)
    }

    func getAllBadges() -> [Badge] {
        [
            Badge(name: "Dummy Badge 1", description: "Simple Description Here", unlockAfterXDays: 1),
            Badge(name: "Dummy Badge 2", description: "Simple Description Here", unlockAfterXDays: 3),
            Badge(name: "Dummy Badge 3", description: "Simple Description Here", unlockAfterXDays: 5),
            Badge(name: "Dummy Badge 4", description: "Simple Description Here", unlockAfterXDays: 7),
            Badge(name: "Dummy Badge 5", description: "Simple Description Here", unlockAfterXDays: 10),
        ]
    }

    func saveAllBadges(_ badges: [Badge], database: Database) async throws {
        for badge in badges {
            try await badge.save(on: database)
        }
    }

    func deleteAllBadges(database: Database) async throws {
        let badges = try await Badge.query(on: database).all()
        for badge in badges {
            try await badge.delete(force: true, on: database)
        }
    }
}
