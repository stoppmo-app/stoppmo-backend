// RateLimitService.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

enum RateLimitService {
    static func emailsService(_ service: EmailRateLimitService) -> EmailRateLimitService {
        service
    }
}
