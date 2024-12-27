import Fluent

struct UserMigrations: MigrationsGroup {
    var migrations: [any Migration] = [CreateUser()]
}