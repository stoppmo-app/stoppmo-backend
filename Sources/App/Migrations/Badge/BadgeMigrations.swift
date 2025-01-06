// BadgeMigrations.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct BadgeMigrations: MigrationsGroup {
    var migrations: [any Migration] = [CreateBadge(), AddAllBadges()]
}
