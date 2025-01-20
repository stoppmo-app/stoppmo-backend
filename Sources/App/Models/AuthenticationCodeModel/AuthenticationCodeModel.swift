import Fluent
import Foundation

// TODO: Create migrations for `AuthenticationCodeModel`
// TODO: Rename all other models to end with the word `Model`, and all the instances where the model name is used

final class AuthenticationCodeModel: Model, @unchecked Sendable {
    static let schema = "authentication_codes"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: Int

    @Field(key: "email")
    var email: String

    @Parent(key: "user_id")
    var user: User

    @Field(key: "expires_at")
    var expiresAt: Date

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        value: Int,
        email: String,
        expiresIn: TimeInterval = 300,
        userID: User.IDValue
    ) {
        self.id = id
        self.value = value
        self.email = email
        self.expiresAt = Date().addingTimeInterval(expiresIn)
        self.$user.id = userID
    }
}
