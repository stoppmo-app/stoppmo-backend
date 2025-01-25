import Fluent

struct UserTokenModelWithExpiresAtAsTimestampZ: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_tokens")
            .updateField("expires_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_tokens")
            .updateField("expires_at", .date)
            .update()
    }
}
