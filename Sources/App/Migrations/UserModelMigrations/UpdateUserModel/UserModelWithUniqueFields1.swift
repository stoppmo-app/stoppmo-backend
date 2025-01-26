// UserModelWithUniqueFields1.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserModelWithUniqueFields1: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .unique(on: "username")
            .unique(on: "phone_number")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteUnique(on: "username")
            .deleteUnique(on: "phone_number")
            .update()
    }
}
