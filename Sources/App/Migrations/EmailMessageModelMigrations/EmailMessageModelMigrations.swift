import Fluent

struct EmailMessageModelMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateEmailMessageModel()
    ]
}
