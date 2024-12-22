import Fluent
import Foundation

final class UserBadge: Model, @unchecked Sendable {
    static let schema = "user_badges"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "started_at")
    var startedAt: Date

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Parent(key: "badge_id")
    var badge: Badge

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(
        id: UUID? = nil,
        startedAt: Date,
        badgeID: Badge.IDValue,
        userID: User.IDValue
    ) {
        self.id = id
        self.startedAt = startedAt
        self.$user.id = userID
        self.$badge.id = badgeID
    }
    
    func toDTO() -> UserBadgeDTO {
        .init(
            id: self.id,
            startedAt: self.startedAt,
            badgeID: self.$badge.$id.value,
            userID: self.$user.$id.value
        )
    }
}
