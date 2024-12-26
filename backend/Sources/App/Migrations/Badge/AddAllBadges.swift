import Fluent

struct AddAllBadges: AsyncMigration {
    func prepare(on database: Database) async throws {
        let badges = self.getAllBadges()
        try await self.saveAllBadges(badges, db: database)
    }

    func revert(on database: Database) async throws {
        try await self.deleteAllBadges(db: database)
    }

    func getAllBadges() -> [Badge] {
        return [
            Badge(name: "Dummy Badge 1", description: "Simple Description Here", unlockAfterXDays: 1),
            Badge(name: "Dummy Badge 2", description: "Simple Description Here", unlockAfterXDays: 3),
            Badge(name: "Dummy Badge 3", description: "Simple Description Here", unlockAfterXDays: 5),
            Badge(name: "Dummy Badge 4", description: "Simple Description Here", unlockAfterXDays: 7),
            Badge(name: "Dummy Badge 5", description: "Simple Description Here", unlockAfterXDays: 10),
        ]
    }

    func saveAllBadges(_ badges: [Badge], db: Database) async throws {
        for badge in badges {
            try await badge.save(on: db)
        }
    }

    func deleteAllBadges(db: Database) async throws {
        let badges = try await Badge.query(on: db).all()
        for badge in badges {
            try await badge.delete(force: true, on: db)
        }
    }
}
