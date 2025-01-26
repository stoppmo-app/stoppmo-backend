import Fluent
import Foundation

final class AuthenticationCodeModel: Model, @unchecked Sendable {
    static let schema = "auth_codes"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: Int

    @Field(key: "email")
    var email: String

    // TODO: add `email_message_id` parent field and create migration.
    // Update code to set this field when saving `AuthenticationCodeModel`

    // TODO: Set `auth_code_type` to `email_message_type` enum
    // (maybe rename the enum to something more generic and update `EmailMessageModel`) to use that instead
    @OptionalParent(key: "user_id")
    var user: UserModel?

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
        userID: UUID? = nil
    ) {
        self.id = id
        self.value = value
        self.email = email
        self.expiresAt = Date().addingTimeInterval(expiresIn)
        self.$user.id = userID
    }
}
