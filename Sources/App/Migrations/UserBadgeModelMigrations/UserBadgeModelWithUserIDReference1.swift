// UserBadgeModelWithUserIDReference1.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserBadgeModelWithParentIDReferences1: AsyncMigration {
    let schema = "user_badges"

    func prepare(on database: Database) async throws {
        try await database.schema(schema)
            .foreignKey("user_id", references: "users", "id")
            .foreignKey("badge_id", references: "badges", "id")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema)
            .deleteForeignKey(name: "user_id")
            .deleteForeignKey(name: "badge_id")
            .update()
    }
}
