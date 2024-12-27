import Fluent
import Vapor

struct UserBadgeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userBadges = routes.grouped("user_badges")

        userBadges.group(":badgeID") { userBadge in
            userBadge.get(use: self.getUserBadgeInfo)
            userBadge.delete(use: self.deleteUserBadge)
            userBadge.patch(use: self.updateUserBadge)
        }

        userBadges.post(use: self.createUserBadge)
        userBadges.get("user", ":userID", use: self.getAllBadgesFromUser)
        userBadges.get("badge", ":badgeID", use: self.getUserBadgesFromBadge)
    }

    @Sendable
    func getUserBadgeInfo(req: Request) async throws -> UserBadgeDTO.GetUserBadge {
        guard
            let userBadge = try await UserBadge.find(
                req.parameters.get("badgeID", as: UUID.self), on: req.db)
        else {
            throw Abort(.notFound)
        }
        return userBadge.toDTO()
    }

    @Sendable
    func deleteUserBadge(req: Request) async throws -> HTTPStatus {
        guard
            let userBadge = try await UserBadge.find(
                req.parameters.get("badgeID", as: UUID.self), on: req.db)
        else {
            throw Abort(.notFound)
        }
        try await userBadge.delete(on: req.db)
        return .noContent
    }

    @Sendable
    func getAllBadgesFromUser(req: Request) async throws -> [UserBadgeDTO.GetUserBadge] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.notFound)
        }
        return try await UserBadge.query(on: req.db).filter(
            "user_id", .equal, userID
        ).all().map { $0.toDTO() }
    }

    @Sendable
    func createUserBadge(req: Request) async throws -> UserBadgeDTO.GetUserBadge {
        let userBadge = UserBadge.fromDTO(try req.content.decode(UserBadgeDTO.CreateUserBadge.self))
        try await userBadge.save(on: req.db)
        return userBadge.toDTO()
    }

    @Sendable
    func updateUserBadge(req: Request) async throws -> UserBadgeDTO.GetUserBadge {
        let updatedUserBadge = try req.content.decode(UserBadgeDTO.UpdateUserBadge.self)

        guard
            let userBadge = try await UserBadge.find(
                req.parameters.get("badgeID", as: UUID.self), on: req.db)
        else {
            throw Abort(.notFound)
        }

        if let claimedAt = updatedUserBadge.claimedAt {
            userBadge.claimedAt = claimedAt
        }
        if let startedAt = updatedUserBadge.startedAt {
            userBadge.startedAt = startedAt
        }

        try await userBadge.update(on: req.db)
        return userBadge.toDTO()
    }

    @Sendable
    func getUserBadgesFromBadge(req: Request) async throws -> [UserBadgeDTO.GetUserBadge] {
        guard let badgeID = req.parameters.get("badgeID", as: UUID.self) else {
            throw Abort(.notFound)
        }

        return try await UserBadge.query(on: req.db).filter("badge_id", .equal, badgeID).all().map {
            $0.toDTO()
        }
    }
}
