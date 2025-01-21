import Fluent

struct CreateEmailMessageModel: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("email_messages")
            .id()
            .field("message", .string, .required)
            .field("sent_at", .date, .required)
            .field("sent_to", .uuid, .required, .references("users", "id"))
            .field("created_at", .date, .required)
            .field("updated_at", .date)
            .field("deleted_at", .date)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("mail_messages").delete()
    }
}
