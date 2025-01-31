// BadgeModelWithUniqueUnlockAfterDaysField1.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct BadgeModelWithUniqueUnlockAfterDaysField1: AsyncMigration {
    let schema = "badges"

    func prepare(on database: Database) async throws {
        try await database.schema(schema)
            .unique(on: "unlock_after_x_days")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema)
            .deleteUnique(on: "unlock_after_x_days")
            .update()
    }
}
