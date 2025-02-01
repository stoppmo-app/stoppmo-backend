// EmailRateLimitServiceTypes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Foundation

protocol EmailRateLimitMessage: Codable {
    mutating func getMessage() -> String
}

enum EmailDailyRateLimitMessage: EmailRateLimitMessage {
    case authCreateAccount(limit: Int)
    case authLogin(limit: Int)

    func getMessage() -> String {
        switch self {
        case let .authCreateAccount(limit):
            "Reached limit of \(limit) account creation attempts for today. Try again in 24 hours."
        case let .authLogin(limit):
            "Reached limit of \(limit) account login attempts for today. Try again in 24 hours."
        }
    }

    static func fromEmailMessageType(messageType: EmailMessageType, limit: Int)
        -> EmailDailyRateLimitMessage
    {
        switch messageType {
        case .authCreateAccount:
            .authCreateAccount(limit: limit)
        case .authLogin:
            .authLogin(limit: limit)
        }
    }
}

enum EmailIntervalRateLimitMessage: EmailRateLimitMessage {
    case authCreateAccount(seconds: Int)
    case authLogin(seconds: Int)

    func getMessage() -> String {
        switch self {
        case let .authCreateAccount(seconds):
            "Too many account creation attempts. Try again in \(seconds) seconds."
        case let .authLogin(seconds):
            "Too many login attempts. Try again in \(seconds) seconds."
        }
    }

    static func fromEmailMessageType(messageType: EmailMessageType, limit: Int)
        -> EmailIntervalRateLimitMessage
    {
        switch messageType {
        case .authCreateAccount:
            .authCreateAccount(seconds: limit)
        case .authLogin:
            .authLogin(seconds: limit)
        }
    }
}
