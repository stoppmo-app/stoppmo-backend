// GetUserBadgeDTO.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

struct GetUserBadgeDTO: Content {
    var id: UUID?
    var startedAt: Date
    var claimedAt: Date
    var badgeID: UUID
    var userID: UUID
    var createdAt: Date?
}
