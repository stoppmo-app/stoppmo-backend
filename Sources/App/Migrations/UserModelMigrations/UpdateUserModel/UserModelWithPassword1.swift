// UserModelWithPassword1.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserModelWithPassword1: AsyncMigration {
    let schema = "users"

    func prepare(on database: Database) async throws {
        try await database.schema(schema)
            .field("password_hash", .string, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema)
            .deleteField("password_hash")
            .deleteUnique(on: "email")
            .update()
    }
}
