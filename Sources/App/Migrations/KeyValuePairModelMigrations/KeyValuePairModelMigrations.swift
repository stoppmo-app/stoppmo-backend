import Fluent

struct KeyValuePairModelMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateKeyValuePairModel()
    ]
}
