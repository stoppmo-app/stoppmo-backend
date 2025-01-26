// UserModelMigrations.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserModelMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateUserModel(), UserModelWithPassword1(), UserModelWithDeletedAt1(),
        UserModelWithUniqueFields1(),
    ]
}
