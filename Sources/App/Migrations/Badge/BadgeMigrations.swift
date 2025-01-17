// BadgeMigrations.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct BadgeMigrations: MigrationsGroup {
    // Keep `AddAllBadges` as the last item
    var migrations: [any Migration] = [CreateBadge(), BadgeWithDeletedAt1(), BadgeWithUniqueUnlockAfterDaysField1(), AddAllBadges()]
}
