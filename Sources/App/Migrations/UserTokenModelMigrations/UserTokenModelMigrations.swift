import Fluent

struct UserTokenModelMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateUserTokenModel(), UserTokenModelWithTimestamps1(),
        UserTokenModelWithExpiresAtField1(),
        UserTokenModelWithExpiresAtAsTimestampZ(),
    ]
}
