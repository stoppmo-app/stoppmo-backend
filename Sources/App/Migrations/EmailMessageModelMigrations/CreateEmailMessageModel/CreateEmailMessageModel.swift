// CreateEmailMessageModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct CreateEmailMessageModel: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("email_messages")
            .id()
            .field("message", .string, .required)
            .field("sent_at", .date, .required)
            .field("sent_to", .uuid, .references("users", "id"))
            .field("created_at", .date, .required)
            .field("updated_at", .date)
            .field("deleted_at", .date)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("email_messages").delete()
    }
}
