import Fluent

struct AuthenticationCodeModelWithEmailMessageIDAndAuthCodeTypeFields: AsyncMigration {
    let schema = "auth_codes"

    func prepare(on database: Database) async throws {
        let authCodeType = try await database.enum("auth_code_type")
            .case("login")
            .case("createAccount")
            .create()

        try await database.schema(schema)
            .field("email_message_id", .uuid, .references("email_messages", "id"))
            .field("code_type", authCodeType, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(schema)
            .deleteField("email_message_id")
            .deleteField("code_type")
            .update()
    }
}
