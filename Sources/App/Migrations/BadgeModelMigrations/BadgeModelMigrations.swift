// BadgeModelMigrations.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct BadgeModelMigrations: MigrationsGroup {
    // Keep `AddAllBadges` as the last item
    var migrations: [any Migration] = [
        CreateBadgeModel(), BadgeModelWithDeletedAt1(), BadgeModelWithUniqueUnlockAfterDaysField1(),
        SeedBadgesModel(),
    ]
}
