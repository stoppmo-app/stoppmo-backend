import Fluent
import Vapor

struct EmailRateLimitService {
    let db: Database

    func emailsSent(
        email: String,
        intervalRateLimit: TimeInterval = 300,
        dailyRateLimit: Int = 10,
        messageTypes: [EmailMessageType],
        intervalRateLimitReachedMessage: String?,
        dailyRateLimitReachedMessage: String?
    ) async throws -> GenericRateLimitResponse {
        let dailyRateLimit = try await self.emailsSentDailyRateLimit(
            email: email, messageTypes: messageTypes, limit: dailyRateLimit,
            message: dailyRateLimitReachedMessage)
        if dailyRateLimit.limitReached == true {
            return dailyRateLimit
        }

        let intervalRateLimit = try await self.emailsSentIntervalLimit(
            email: email, limit: intervalRateLimit, message: intervalRateLimitReachedMessage)
        if intervalRateLimit.limitReached == true {
            return intervalRateLimit
        }
        return .init(limitReached: false)
    }

    private func emailsSentDailyRateLimit(
        email: String,
        messageTypes: [EmailMessageType],
        limit: Int,
        message: String?
    ) async throws -> GenericRateLimitResponse {
        if try await EmailMessageModel
            .query(on: db)
            .filter(\.$sentToEmail == email)
            .filter(\.$messageType ~~ messageTypes)
            .filter(\.$sentAt >= Date().addingTimeInterval(-86400))
            .filter(\.$sentAt <= Date())
            .count() >= limit
        {
            return .init(
                limitReached: true,
                message:
                    message
                    ?? "Too many emails sent for today. Try again in 24 hours."
            )
        }
        return .init(
            limitReached: false
        )
    }

    private func emailsSentIntervalLimit(
        email: String,
        limit: TimeInterval,
        message: String?
    ) async throws -> GenericRateLimitResponse {
        guard
            let latestSentAt =
                try await EmailMessageModel
                .query(on: db)
                .filter(\.$sentToEmail == email)
                .sort(\.$sentAt, .ascending)
                .first()
        else {
            // User sent no emails, meaning they aren't rate limited
            return .init(limitReached: false)
        }

        let rateLimited = latestSentAt.sentAt < Date().addingTimeInterval(-limit)
        if rateLimited == true {
            return .init(
                limitReached: rateLimited,
                message: message
                    ?? "Rate limit reached for sending emails. Try again in \(limit) seconds."
            )
        }
        return .init(limitReached: false)
    }
}
