// UserMigrations.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct UserMigrations: MigrationsGroup {
    var migrations: [any Migration] = [CreateUser()]
}
