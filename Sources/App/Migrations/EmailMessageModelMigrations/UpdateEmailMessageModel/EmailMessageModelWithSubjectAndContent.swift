// EmailMessageModelWithSubjectAndContent.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct EmailMessageModelWithSubjectAndContent: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("email_messages")
            .deleteField("message")
            .field("subject", .string, .required)
            .field("content", .string, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("email_messages")
            .field("message", .string, .required)
            .deleteField("subject")
            .deleteField("subject")
            .update()
    }
}
