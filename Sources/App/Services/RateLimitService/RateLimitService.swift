// RateLimitService.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

// TODO: Test out `EmailRateLimitService().emailsSent()` method
// TODO: Write tests for all rate limit services code

enum RateLimitService {
    static func emailsService(_ service: EmailRateLimitService) -> EmailRateLimitService {
        service
    }
}
