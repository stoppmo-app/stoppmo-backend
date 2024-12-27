import Vapor

struct UpdateUserBadgeDTO: Content {
    var startedAt: Date?
    var claimedAt: Date?
}