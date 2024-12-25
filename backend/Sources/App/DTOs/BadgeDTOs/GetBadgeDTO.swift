import Vapor

struct GetBadgeDTO: Content {
    var name: String
    var description: String
    var unlockAfterXDays: Int
}