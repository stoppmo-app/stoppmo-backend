// UserBadgeWithDeletedAt1.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserBadgeWithDeletedAt1: AsyncMigration {
    func prepare(on database: Database) async throws {

        try await database.schema("user_badges")
            .field("deleted_at", .date)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_badges")
            .deleteField("deleted_at")
            .update()
    }
}
