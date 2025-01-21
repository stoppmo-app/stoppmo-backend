import Fluent

struct EmailMessageModelWithEmailMessageTypeEnum: AsyncMigration {
    func prepare(on database: Database) async throws {
        let emailMessageType = try await database.enum("email_message_type")
            .case("authLogin")
            .case("authCreateAccount")
            .create()

        try await database.schema("email_messages")
            .field("message_type", emailMessageType, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("email_messages")
            .deleteField("message_type")
            .update()
    }
}
