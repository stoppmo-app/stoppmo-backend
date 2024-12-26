import Fluent

struct BadgeMigrations: MigrationsGroup {
    var migrations: [any Migration] = [CreateBadge(), AddAllBadges()]
}