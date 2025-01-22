// UserBadgeController.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

struct UserBadgeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userBadges = routes.grouped("user_badges")

        userBadges.group(":badgeID") { userBadge in
            userBadge.get(use: getUserBadgeInfo)
            userBadge.delete(use: deleteUserBadge)
            userBadge.patch(use: updateUserBadge)
        }

        userBadges.post(use: createUserBadge)
        userBadges.get("user", ":userID", use: getAllBadgesFromUser)
        userBadges.get("badge", ":badgeID", use: getUserBadgesFromBadge)
    }

    @Sendable
    func getUserBadgeInfo(req: Request) async throws -> UserBadgeDTO.GetUserBadge {
        guard
            let userBadge = try await UserBadgeModel.find(
                req.parameters.get("badgeID", as: UUID.self), on: req.db
            )
        else {
            throw Abort(.notFound)
        }
        return userBadge.toDTO()
    }

    @Sendable
    func deleteUserBadge(req: Request) async throws -> HTTPStatus {
        guard
            let userBadge = try await UserBadgeModel.find(
                req.parameters.get("badgeID", as: UUID.self), on: req.db
            )
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

        return try await UserBadgeModel.query(on: req.db).filter(
            "user_id", .equal, userID
        ).all().map { $0.toDTO() }
    }

    @Sendable
    func createUserBadge(req: Request) async throws -> UserBadgeDTO.GetUserBadge {
        let userBadge = try UserBadgeModel.fromDTO(
            req.content.decode(UserBadgeDTO.CreateUserBadge.self))
        try await userBadge.save(on: req.db)
        return userBadge.toDTO()
    }

    @Sendable
    func updateUserBadge(req: Request) async throws -> UserBadgeDTO.GetUserBadge {
        let updatedUserBadge = try req.content.decode(UserBadgeDTO.UpdateUserBadge.self)

        guard
            let userBadge = try await UserBadgeModel.find(
                req.parameters.get("badgeID", as: UUID.self), on: req.db
            )
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

        return try await UserBadgeModel.query(on: req.db).filter(\.$badge.$id, .equal, badgeID)
            .all()
            .map {
                $0.toDTO()
            }
    }
}
