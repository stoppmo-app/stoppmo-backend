// CreateBadgeModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct CreateBadgeModel: AsyncMigration {
    let schema = "badges"

    func prepare(on database: Database) async throws {
        try await database.schema(schema)
            .id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("unlock_after_x_days", .int, .required)
            .field("created_at", .date, .required)
            .field("updated_at", .date)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema).delete()
    }
}
