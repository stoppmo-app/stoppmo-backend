import Fluent

struct UserBadgeModelMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateUserBadgeModel(), UserBadgeModelWithParentIDReferences1(),
        UserBadgeModelWithDeletedAt1(),
    ]
}
