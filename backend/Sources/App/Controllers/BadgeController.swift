import Fluent
import Vapor

struct BadgeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let badges = routes.grouped("badges")
        badges.get(use: self.getAllBadges)
        badges.get(":badgeID", use: self.getBadgeInfo)
    }

    @Sendable
    func getAllBadges(req: Request) async throws -> [BadgeDTO.GetBadge] {
        try await Badge.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func getBadgeInfo(req: Request) async throws -> BadgeDTO.GetBadge {
        guard let badge = try await Badge.find(req.parameters.get("badgeID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return badge.toDTO()
    }

}
