// UserWithPassword1.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserWithPassword1: AsyncMigration {
    func prepare(on database: Database) async throws {

        try await database.schema("users")
            .field("password_hash", .string, .required)
            .unique(on: "email")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("password_hash")
            .deleteUnique(on: "email")
            .update()
    }
}
