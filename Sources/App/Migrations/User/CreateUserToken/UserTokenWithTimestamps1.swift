// UserTokenWithTimestamps1.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserTokenWithTimestamps1: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_tokens")
            .field("created_at", .date, .required)
            .field("updated_at", .date)
            .field("deleted_at", .date)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_tokens")
            .deleteField("created_at")
            .deleteField("updated_at")
            .deleteField("deleted_at")
            .update()
    }
}
