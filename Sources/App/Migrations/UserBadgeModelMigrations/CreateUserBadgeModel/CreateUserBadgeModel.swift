// CreateUserBadgeModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct CreateUserBadgeModel: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_badges")
            .id()
            .field("started_at", .date, .required)
            .field("claimed_at", .date, .required)
            .field("badge_id", .uuid, .required)
            .field("user_id", .uuid, .required)
            .field("created_at", .date, .required)
            .field("updated_at", .date)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_badges").delete()
    }
}
