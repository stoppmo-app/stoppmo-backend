import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        let role = try await database.enum("user_role")
            .case("member")
            .case("admin")
            .create()

        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("surname", .string, .required)
            .field("username", .string, .required)
            .field("role", role, .required)
            .field("created_at", .string, .required)
            .field("updated_at", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
