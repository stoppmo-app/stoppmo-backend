import Fluent

struct EmailMessageModelWithTimestampzSentAt: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("email_messages")
            .updateField("sent_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("email_messages")
            .updateField("sent_at", .date)
            .update()
    }
}
