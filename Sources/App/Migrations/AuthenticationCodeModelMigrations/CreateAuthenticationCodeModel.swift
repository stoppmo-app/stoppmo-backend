import Fluent

struct CreateAuthenticationCodeModel: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("auth_codes")
            .id()
            .field("value", .int, .required)
            .field("email", .string, .required)
            .field("user_id", .uuid, .required, .references("user$", "id"))
            .field("expires_at", .date, .required)
            .field("created_at", .date, .required)
            .field("updated_at", .date)
            .field("deleted_at", .date)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("auth_codes").delete()
    }
}
