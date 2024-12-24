import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        let userRole : DatabaseSchema.DataType.Enum = .init(name: "UserRole", cases: ["admin, member"])

        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("surname", .string, .required)
            .field("password", .string, .required)
            .field("user_role", .enum(userRole), .required)
            .field("created_at", .string, .required)
            .field("updated_at", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
