import Fluent

struct UserBadgeMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateUserBadgeModel(), UserBadgeModelWithParentIDReferences1(),
        UserBadgeModelWithDeletedAt1(),
    ]
}
