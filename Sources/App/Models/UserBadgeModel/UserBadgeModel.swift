import Fluent
import Foundation

final class UserBadgeModel: Model, @unchecked Sendable {
    static let schema = "user_badges"

    @ID(key: .id)
    var id: UUID?

    // Date when the streak started to unlock this badge
    @Field(key: "started_at")
    var startedAt: Date

    @Field(key: "claimed_at")
    var claimedAt: Date

    @Parent(key: "badge_id")
    var badge: BadgeModel

    @Parent(key: "user_id")
    var user: UserModel

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
   var deletedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        startedAt: Date,
        claimedAt: Date,
        badgeID: UUID,
        userID: UUID
    ) {
        self.id = id
        self.startedAt = startedAt
        self.claimedAt = claimedAt
        $user.id = userID
        $badge.id = badgeID
    }

    func toDTO() -> UserBadgeDTO.GetUserBadge {
        .init(
            id: id,
            startedAt: startedAt,
            claimedAt: claimedAt,
            badgeID: $badge.id,
            userID: $user.id,
            createdAt: createdAt
        )
    }

    static func fromDTO(_ dto: UserBadgeDTO.CreateUserBadge) -> UserBadgeModel {
        .init(
            startedAt: dto.startedAt, claimedAt: dto.claimedAt, badgeID: dto.badgeID,
            userID: dto.userID)
    }
}
