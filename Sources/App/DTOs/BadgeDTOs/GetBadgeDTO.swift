// GetBadgeDTO.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

struct GetBadgeDTO: Content {
    var id: UUID?
    var name: String
    var description: String
    var unlockAfterXDays: Int
}
