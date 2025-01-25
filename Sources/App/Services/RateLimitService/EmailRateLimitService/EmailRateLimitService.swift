import Fluent
import Vapor

struct EmailRateLimitService {
    let db: Database
    let logger: Logger

    func emailsSent(
        email: String,
        intervalRateLimit: TimeInterval,
        dailyRateLimit: Int,
        messageTypes: [EmailMessageType],
        intervalRateLimitReachedMessage: EmailIntervalRateLimitMessage,
        dailyRateLimitReachedMessage: EmailDailyRateLimitMessage
    ) async throws -> GenericRateLimitResponse {
        let dailyRateLimitResponse = try await self.emailsSentDailyRateLimit(
            email: email, messageTypes: messageTypes, limit: dailyRateLimit,
            message: intervalRateLimitReachedMessage.getMessage())
        if dailyRateLimitResponse.limitReached == true {
            return dailyRateLimitResponse
        }

        let intervalRateLimitResponse = try await self.emailsSentIntervalLimit(
            email: email, limit: intervalRateLimit,
            message: intervalRateLimitReachedMessage.getMessage())
        if intervalRateLimitResponse.limitReached == true {
            return intervalRateLimitResponse
        }

        return .init(limitReached: false)
    }

    private func emailsSentDailyRateLimit(
        email: String,
        messageTypes: [EmailMessageType],
        limit: Int,
        message: String
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
                message: message
            )
        }
        return .init(
            limitReached: false
        )
    }

    private func emailsSentIntervalLimit(
        email: String,
        limit: TimeInterval,
        message: String
    ) async throws -> GenericRateLimitResponse {
        guard
            let latestSentAt =
                try await EmailMessageModel
                .query(on: db)
                .filter(\.$sentToEmail == email)
                .sort(\.$sentAt, .descending)
                .first()
        else {
            // User sent no emails, meaning they aren't rate limited
            return .init(limitReached: false)
        }

        let rateLimited = latestSentAt.sentAt.addingTimeInterval(limit) >= Date()
        if rateLimited == true {
            return .init(
                limitReached: rateLimited,
                message: message
            )
        }
        return .init(limitReached: false)
    }

    public func authEmailsSent(email: String, messageType: EmailMessageType) async throws
        -> GenericRateLimitResponse
    {
        let intervalRateLimit = 100
        let dailyRateLimit = 20

        let rateLimitResponse = try await self.emailsSent(
            email: email,
            intervalRateLimit: TimeInterval(intervalRateLimit),
            dailyRateLimit: dailyRateLimit,
            messageTypes: [messageType],
            intervalRateLimitReachedMessage: .fromEmailMessageType(
                messageType: messageType,
                limit: intervalRateLimit
            ),
            dailyRateLimitReachedMessage: .fromEmailMessageType(
                messageType: messageType,
                limit: dailyRateLimit
            ))
        return rateLimitResponse
    }
}
