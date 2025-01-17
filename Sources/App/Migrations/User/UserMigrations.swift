// UserMigrations.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateUser(), CreateUserToken(), UserWithPassword1(), UserWithDeletedAt1(),
        UserTokenWithTimestamps1(), UserWithUniqueFields1(), UserTokenWithExpiresAtField1(),
    ]
}
