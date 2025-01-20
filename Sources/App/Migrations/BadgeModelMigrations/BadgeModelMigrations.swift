import Fluent

struct BadgeModelMigrations: MigrationsGroup {
    // Keep `AddAllBadges` as the last item
    var migrations: [any Migration] = [
        CreateBadgeModel(), BadgeModelWithDeletedAt1(), BadgeModelWithUniqueUnlockAfterDaysField1(),
        SeedBadgesModel(),
    ]
}
