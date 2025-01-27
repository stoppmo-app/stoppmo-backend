// CreateAuthenticationCodeModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct CreateAuthenticationCodeModel: AsyncMigration {
    let schema = "auth_codes"

    func prepare(on database: Database) async throws {
        try await database.schema(schema)
            .id()
            .field("value", .int, .required)
            .field("email", .string, .required)
            .field("user_id", .uuid, .references("users", "id"))
            .field("expires_at", .date, .required)
            .field("created_at", .date, .required)
            .field("updated_at", .date)
            .field("deleted_at", .date)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema).delete()
    }
}
