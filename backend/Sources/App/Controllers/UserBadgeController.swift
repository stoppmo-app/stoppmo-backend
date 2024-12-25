import Fluent
import Vapor

struct UserBadgeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userBadges = routes.grouped("user_badges")

        userBadges.get(":badgeID", use: self.getAllBadgesFromUser)

        userBadges.group("user") { user in
            user.get(use: self.getAllBadgesFromUser)
            user.post(use: self.createUserBadge)
            user.patch(use: self.updateUserBadge)
            user.delete(":userID", use: self.deleteUserBadge)
        }
    }

    @Sendable
    func getUserBadgeInfo(req: Request) async throws -> UserBadgeDTO.GetUserBadge {
        guard let userBadge = try await UserBadge.find(req.parameters.get("badgeID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return userBadge.toDTO()
    }

    @Sendable
    func getAllBadgesFromUser(req: Request) async throws -> [UserBadgeDTO.GetUserBadge] {
        try await UserBadge.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func createUserBadge(req: Request) async throws -> [UserBadgeDTO.GetUserBadge] {
        let userBadge = UserBadge.fromDTO(try req.content.decode(UserBadgeDTO.CreateUserBadge.self))
        try await userBadge.save(on: req.db)
        return userBadge.toDTO()
    }

    @Sendable
    func updateUserBadge(req: Request) async throws -> [UserBadgeDTO.GetUserBadge] {
        let updatedUserBadge = try req.content.decode(UserBadgeDTO.UpdateUserBadge.self)

        guard let userBadge = try await UserBadge.find(updatedUserBadge.id, on: req.db) else {
            throw Abort(.notFound)
        }

        // TODO: update all the badge properties here

        // user.firstName = updatedUser.firstName ?? user.firstName
        // user.lastName = updatedUser.lastName ?? user.lastName
        // user.username = updatedUser.username ?? user.lastName
        // user.username = updatedUser.username ?? user.lastName
        // user.profilePictureURL = updatedUser.profilePictureURL ?? user.profilePictureURL
        // user.bio = updatedUser.bio ?? user.bio
        // user.dateOfBirth = updatedUser.dateOfBirth ?? user.dateOfBirth
        // user.phoneNumber = updatedUser.phoneNumber ?? user.phoneNumber

        try await userBadge.update(on: req.db)
        return userBadge.toDTO()
    }

    @Sendable
    func deleteUserBadge(req: Request) async throws -> HTTPStatus {
        guard let userBadge = try await UserBadge.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await userBadge.delete(on: req.db)
        return .noContent
    }
}
