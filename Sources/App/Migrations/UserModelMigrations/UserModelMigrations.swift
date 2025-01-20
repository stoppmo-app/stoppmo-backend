import Fluent

struct UserMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateUserModel(), UserModelWithPassword1(), UserModelWithDeletedAt1(),
        UserModelWithUniqueFields1(),
    ]
}
