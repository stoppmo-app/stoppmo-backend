// UserBadgeModelMigrations.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserBadgeModelMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateUserBadgeModel(), UserBadgeModelWithParentIDReferences1(),
        UserBadgeModelWithDeletedAt1(),
    ]
}
