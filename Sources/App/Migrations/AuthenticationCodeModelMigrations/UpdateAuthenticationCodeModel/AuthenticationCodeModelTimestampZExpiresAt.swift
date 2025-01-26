// AuthenticationCodeModelTimestampZExpiresAt.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct AuthenticationCodeModelTimestampZExpiresAt: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("auth_codes")
            .updateField("expires_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("auth_codes")
            .updateField("expires_at", .date)
            .update()
    }
}
