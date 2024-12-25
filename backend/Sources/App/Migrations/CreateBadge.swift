import Fluent

struct CreateBadge: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("badges")
            .id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("unlock_after_x_days", .int, .required)
            .field("created_at", .string, .required)
            .field("updated_at", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("badges").delete()
    }
}
