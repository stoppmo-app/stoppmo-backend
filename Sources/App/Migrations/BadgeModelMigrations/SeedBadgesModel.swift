// SeedBadgesModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct SeedBadgesModel: AsyncMigration {
    func prepare(on database: Database) async throws {
        let badges = getAllBadges()
        try await saveAllBadges(badges, database: database)
    }

    func revert(on database: Database) async throws {
        try await deleteAllBadges(database: database)
    }

    func getAllBadges() -> [BadgeModel] {
        [
            BadgeModel(
                name: "Dummy BadgeModel 1", description: "Simple Description Here",
                unlockAfterXDays: 1
            ),
            BadgeModel(
                name: "Dummy BadgeModel 2", description: "Simple Description Here",
                unlockAfterXDays: 3
            ),
            BadgeModel(
                name: "Dummy BadgeModel 3", description: "Simple Description Here",
                unlockAfterXDays: 5
            ),
            BadgeModel(
                name: "Dummy BadgeModel 4", description: "Simple Description Here",
                unlockAfterXDays: 7
            ),
            BadgeModel(
                name: "Dummy BadgeModel 5", description: "Simple Description Here",
                unlockAfterXDays: 10
            ),
        ]
    }

    func saveAllBadges(_ badges: [BadgeModel], database: Database) async throws {
        for badge in badges {
            try await badge.save(on: database)
        }
    }

    func deleteAllBadges(database: Database) async throws {
        let badges = try await BadgeModel.query(on: database).all()
        for badge in badges {
            try await badge.delete(force: true, on: database)
        }
    }
}
