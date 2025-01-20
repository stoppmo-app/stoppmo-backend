import Fluent

struct UserBadgeModelWithDeletedAt1: AsyncMigration {
    func prepare(on database: Database) async throws {

        try await database.schema("user_badges")
            .field("deleted_at", .date)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_badges")
            .deleteField("deleted_at")
            .update()
    }
}
