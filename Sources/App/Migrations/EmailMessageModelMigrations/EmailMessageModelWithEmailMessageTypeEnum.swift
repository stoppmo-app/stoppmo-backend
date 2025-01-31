// EmailMessageModelWithEmailMessageTypeEnum.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct EmailMessageModelWithEmailMessageTypeEnum: AsyncMigration {
    let schema = "email_messages"

    func prepare(on database: Database) async throws {
        let emailMessageType = try await database.enum("email_message_type")
            .case("authLogin")
            .case("authCreateAccount")
            .create()

        try await database.schema(schema)
            .field("message_type", emailMessageType, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema)
            .deleteField("message_type")
            .update()
    }
}
