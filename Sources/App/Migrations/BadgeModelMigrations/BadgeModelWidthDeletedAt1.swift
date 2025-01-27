// BadgeModelWidthDeletedAt1.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct BadgeModelWithDeletedAt1: AsyncMigration {
    let schema = "badges"

    func prepare(on database: Database) async throws {
        try await database.schema(schema)
            .field("deleted_at", .date)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema)
            .deleteField("deleted_at")
            .update()
    }
}
