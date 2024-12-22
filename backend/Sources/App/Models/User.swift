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

    @Enum(key: "user_role")
    var userRole: UserRole

    @Children(for: \.$user)
    var badgesHistory: [UserBadge]

    // When this Planet was created.
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // When this Planet was last updated.
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?


    init() { }

    init(
        id: UUID? = nil,
        name: String,
        surname: String,
        username: String,
        password: String,
        userRole: UserRole
    ) {
        self.id = id
        self.name = name
        self.surname = surname
        self.username = username
        self.password = password
        self.userRole = userRole

    }
    
    func toDTO() -> UserDTO {
        .init(
            id: self.id,
            name: self.$name.value,
            surname: self.$surname.value,
            username: self.$username.value,
            password: self.$password.value,
            userRole: self.$userRole.value
        )
    }
}
