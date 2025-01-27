// CreateKeyValuePairModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct CreateKeyValuePairModel: AsyncMigration {
    let schema = "key_value_pairs"

    func prepare(on database: Database) async throws {
        let pairType = try await database.enum("key_value_pair_type")
            .case("zohoAccessToken")
            .create()

        try await database.schema(schema)
            .id()
            .field("pair_type", pairType, .required)
            .field("key", .string, .required)
            .field("value", .string, .required)
            .field("metadata", .string)
            .field("user_id", .uuid, .references("users", "id"))
            .field("created_at", .date, .required)
            .field("updated_at", .date)
            .field("deleted_at", .date)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema).delete()
    }
}
