// UpdateUserBadgeDTO.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

struct UpdateUserBadgeDTO: Content {
    var startedAt: Date?
    var claimedAt: Date?
}
