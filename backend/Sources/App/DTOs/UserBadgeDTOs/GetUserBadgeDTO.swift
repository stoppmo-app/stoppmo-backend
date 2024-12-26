import Vapor

struct GetUserBadgeDTO: Content {
    var startedAt: Date
    var claimedAt: Date
    var badgeID: UUID
    var userID: UUID
    var createdAt: Date?
}