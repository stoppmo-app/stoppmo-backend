import Fluent
import Vapor

struct RateLimitService {
    let db: Database

    func authEmailsSent(email: String, intervalRateLimit: Int = 300, dailyRateLimit: Int = 10)
        async throws -> Bool
    {
        // 1. Get length of all authentication emails sent to user in the past 24 hours, order newest to oldest (`created_at` field)
        //  - If length >= dailyRateLimit, return false
        // 2. If latestEmail.createdAt was sent less than 5 minutes ago, return false
        return false
    }
}
