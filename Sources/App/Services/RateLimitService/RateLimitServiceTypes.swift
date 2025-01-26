// RateLimitServiceTypes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

protocol RateLimitResponse {
    var limitReached: Bool { get }
    var message: String? { get }
}

struct GenericRateLimitResponse: RateLimitResponse {
    var limitReached: Bool
    var message: String?
}

enum RateLimitType: String, Codable {
    case interval
    case daily
}
