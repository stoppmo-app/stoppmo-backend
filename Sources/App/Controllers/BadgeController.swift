// BadgeController.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

struct BadgeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let badges = routes.grouped("badges")
        badges.get(use: getAllBadges)
        badges.get(":badgeID", use: getBadgeInfo)
    }

    @Sendable
    func getAllBadges(req: Request) async throws -> [BadgeDTO.GetBadge] {
        try await Badge.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func getBadgeInfo(req: Request) async throws -> BadgeDTO.GetBadge {
        guard let badge = try await Badge.find(req.parameters.get("badgeID", as: UUID.self), on: req.db) else {
            throw Abort(.notFound)
        }
        return badge.toDTO()
    }
}
