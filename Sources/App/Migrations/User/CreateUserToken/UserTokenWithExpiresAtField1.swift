import Fluent

struct UserTokenWithExpiresAtField1: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_tokens")
            .field("expires_at", .date, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_tokens")
            .deleteField("expires_at")
            .update()
    }
}
