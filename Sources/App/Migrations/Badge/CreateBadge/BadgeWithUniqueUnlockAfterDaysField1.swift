import Fluent

struct BadgeWithUniqueUnlockAfterDaysField1: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("badges")
            .unique(on: "unlock_after_x_days")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("badges")
            .deleteUnique(on: "unlock_after_x_days")
            .update()
    }
}
