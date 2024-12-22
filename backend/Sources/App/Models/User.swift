import Fluent
import Foundation

enum UserRole: String, Codable {
    case admin, member
}

final class User: Model, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "surname")
    var surname: String

    @Field(key: "username")
    var username: String

    @Field(key: "password")
    var password: String

    // When this Planet was created.
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // When this Planet was last updated.
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Enum(key: "user_role")
    var userRole: UserRole

    @Children(for: \.$user)
    var badgesHistory: [UserBadge]

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
