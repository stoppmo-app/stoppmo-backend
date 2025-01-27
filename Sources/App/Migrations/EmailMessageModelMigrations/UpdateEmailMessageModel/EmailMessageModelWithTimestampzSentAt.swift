// EmailMessageModelWithTimestampzSentAt.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct EmailMessageModelWithTimestampzSentAt: AsyncMigration {
    let schema = "email_messages"
    func prepare(on database: Database) async throws {
        try await database.schema(schema)
            .updateField("sent_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema)
            .updateField("sent_at", .date)
            .update()
    }
}
