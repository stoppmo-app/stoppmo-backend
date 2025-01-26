// AuthenticationCodeModelMigrations.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct AuthenticationCodeModelMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateAuthenticationCodeModel(),
        AuthenticationCodeModelTimestampZExpiresAt(),
    ]
}
