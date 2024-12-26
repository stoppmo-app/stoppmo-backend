import Fluent

struct UserBadgeMigrations: MigrationsGroup {
    var migrations: [any Migration] = [CreateUserBadge()]
}