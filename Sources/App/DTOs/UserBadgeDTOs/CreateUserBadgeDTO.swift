import Vapor

struct CreateUserBadgeDTO: Content {
    var startedAt: Date
    var claimedAt: Date
    var badgeID: UUID
    var userID: UUID
}