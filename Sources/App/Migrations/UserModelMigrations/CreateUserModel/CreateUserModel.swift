// CreateUserModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct CreateUserModel: AsyncMigration {
    func prepare(on database: Database) async throws {
        let role = try await database.enum("user_role")
            .case("member")
            .case("admin")
            .create()

        try await database.schema("users")
            .id()
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("username", .string, .required)
            .field("email", .string, .required)
            .field("role", role, .required)
            .field("profile_picture_url", .string, .required)
            .field("bio", .string, .required)
            .field("phone_number", .string, .required)
            .field("date_of_birth", .date, .required)
            .field("created_at", .date, .required)
            .field("updated_at", .date)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
