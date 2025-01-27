// EmailMessageModelWithSubjectAndContent.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct EmailMessageModelWithSubjectAndContent: AsyncMigration {
    let schema = "email_messages"

    func prepare(on database: Database) async throws {
        try await database.schema(schema)
            .deleteField("message")
            .field("subject", .string, .required)
            .field("content", .string, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema)
            .field("message", .string, .required)
            .deleteField("subject")
            .deleteField("subject")
            .update()
    }
}
