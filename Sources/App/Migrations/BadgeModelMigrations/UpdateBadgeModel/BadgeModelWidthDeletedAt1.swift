import Fluent

struct BadgeModelWithDeletedAt1: AsyncMigration {
    func prepare(on database: Database) async throws {

        try await database.schema("badges")
            .field("deleted_at", .date)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("badges")
            .deleteField("deleted_at")
            .update()
    }
}
