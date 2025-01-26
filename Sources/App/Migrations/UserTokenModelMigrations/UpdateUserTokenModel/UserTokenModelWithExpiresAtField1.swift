// UserTokenModelWithExpiresAtField1.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserTokenModelWithExpiresAtField1: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_tokens")
            .field("expires_at", .date, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_tokens")
            .deleteField("expires_at")
            .update()
    }
}
