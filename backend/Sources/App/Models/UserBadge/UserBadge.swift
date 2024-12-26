import Fluent
import Foundation

final class UserBadge: Model, @unchecked Sendable {
    static let schema = "user_badges"
    
    @ID(key: .id)
    var id: UUID?

    // Date when the streak started to unlock this badge
    @Field(key: "started_at")
    var startedAt: Date

    @Field(key: "claimed_at")
    var claimedAt: Date

    @Parent(key: "badge_id")
    var badge: Badge

    @Parent(key: "user_id")
    var user: User

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(
        id: UUID? = nil,
        startedAt: Date,
        claimedAt: Date,
        badgeID: Badge.IDValue,
        userID: User.IDValue
    ) {
        self.id = id
        self.startedAt = startedAt
        self.claimedAt = claimedAt
        self.$user.id = userID
        self.$badge.id = badgeID
    }


    func toDTO() -> UserBadgeDTO.GetUserBadge {
        return .init(startedAt: self.startedAt, claimedAt: self.claimedAt, badgeID: self.$badge.id, userID: self.$user.id, createdAt: self.createdAt)
    }

    static func fromDTO(_ dto: UserBadgeDTO.CreateUserBadge) -> UserBadge {
        return .init(startedAt: dto.startedAt, claimedAt: dto.claimedAt, badgeID: dto.badgeID, userID: dto.userID)
    }
}
