import Fluent

struct UserModelWithPassword1: AsyncMigration {
    func prepare(on database: Database) async throws {

        try await database.schema("users")
            .field("password_hash", .string, .required)
            .unique(on: "email")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("password_hash")
            .deleteUnique(on: "email")
            .update()
    }
}
