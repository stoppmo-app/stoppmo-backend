// EmailRateLimitService.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

struct EmailRateLimitService {
    let database: Database
    let logger: Logger

    // test
    struct IntervalAndDailyRateLimit: Content {
        let intervalRateLimit: TimeInterval
        let dailyRateLimit: Int
    }

    func emailsSent(
        email: String,
        rateLimit: IntervalAndDailyRateLimit,
        messageTypes: [EmailMessageType],
        intervalRateLimitReachedMessage: EmailIntervalRateLimitMessage,
        dailyRateLimitReachedMessage: EmailDailyRateLimitMessage
    ) async throws {
        let intervalRateLimit = rateLimit.intervalRateLimit
        let dailyRateLimit: Int = rateLimit.dailyRateLimit

        let dailyLimitMessage = dailyRateLimitReachedMessage.getMessage()
        let intervalLimitMessage = intervalRateLimitReachedMessage.getMessage()

        var finalErrorMessage: String = ""

        if try await emailsSentDailyRateLimit(
            email: email, messageTypes: messageTypes, limit: dailyRateLimit
        ) {
            finalErrorMessage.append(dailyLimitMessage)
        }

        if try await emailsSentIntervalLimit(
            email: email, limit: intervalRateLimit
        ) {
            finalErrorMessage.append(intervalLimitMessage)
        }
        if finalErrorMessage != "" {
            throw Abort(.custom(code: 429, reasonPhrase: finalErrorMessage))
        }
    }

    private func emailsSentDailyRateLimit(
        email: String,
        messageTypes: [EmailMessageType],
        limit: Int
    ) async throws -> Bool {
        return try await EmailMessageModel
            .query(on: database)
            .filter(\.$sentToEmail == email)
            .filter(\.$messageType ~~ messageTypes)
            .filter(\.$sentAt >= Date().addingTimeInterval(-86400))
            .filter(\.$sentAt <= Date())
            .count() >= limit
    }

    private func emailsSentIntervalLimit(
        email: String,
        limit: TimeInterval
    ) async throws -> Bool {
        guard
            let latestSentAt =
                try await EmailMessageModel
                .query(on: database)
                .filter(\.$sentToEmail == email)
                .sort(\.$sentAt, .descending)
                .first()
        else {
            // User sent no emails, meaning they aren't rate limited
            return false
        }

        return latestSentAt.sentAt.addingTimeInterval(limit) >= Date()
    }

    public func authEmailsSent(email: String, messageType: EmailMessageType) async throws {
        let intervalRateLimit = 100
        let dailyRateLimit = 20

        try await emailsSent(
            email: email,
            rateLimit: .init(
                intervalRateLimit: TimeInterval(intervalRateLimit), dailyRateLimit: dailyRateLimit
            ),
            messageTypes: [messageType],
            intervalRateLimitReachedMessage: .fromEmailMessageType(
                messageType: messageType,
                limit: intervalRateLimit
            ),
            dailyRateLimitReachedMessage: .fromEmailMessageType(
                messageType: messageType,
                limit: dailyRateLimit
            )
        )
    }
}
