// EmailMessageModelWithSentToAndSentFromEmail.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct EmailMessageModelWithSentToAndSentFromEmail: AsyncMigration {
    let schema = "email_messages"

    func prepare(on database: Database) async throws {
        try await database.schema(schema)
            .field("sent_to_email", .string, .required)
            .field("sent_from_email", .string, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema)
            .deleteField("sent_to_email")
            .deleteField("sent_from_email")
            .update()
    }
}
