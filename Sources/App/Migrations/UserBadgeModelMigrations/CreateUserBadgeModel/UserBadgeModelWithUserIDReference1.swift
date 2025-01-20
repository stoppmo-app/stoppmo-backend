import Fluent

struct UserBadgeModelWithParentIDReferences1: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_badges")
            .foreignKey("user_id", references: "users", "id")
            .foreignKey("badge_id", references: "badges", "id")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_badges")
            .deleteForeignKey(name: "user_id")
            .deleteForeignKey(name: "badge_id")
            .update()
    }
}
