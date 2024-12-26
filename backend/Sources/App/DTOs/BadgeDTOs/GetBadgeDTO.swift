import Vapor

struct GetBadgeDTO: Content {
    var id: UUID?
    var name: String
    var description: String
    var unlockAfterXDays: Int
}