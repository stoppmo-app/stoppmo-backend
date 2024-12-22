import Fluent
import Foundation

final class UserBadge: Model, @unchecked Sendable {
    static let schema = "user_badges"
    
    @ID(key: .id)
    var id: UUID?

    @Timestamp(key: "started_at", on: .none)
    var startedAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Parent(key: "badge_id")
    var badge: [Badge]

    @Parent(key: "user_id")
    var user: [User]

    init() { }

    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
    
    func toDTO() -> TodoDTO {
        .init(
            id: self.id,
            title: self.$title.value
        )
    }
}
