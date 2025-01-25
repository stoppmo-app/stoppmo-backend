import Fluent
import Vapor

final class UserTokenModel: Model, Content, @unchecked Sendable {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Field(key: "expires_at")
    var expiresAt: Date

    @Parent(key: "user_id")
    var user: UserModel

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() {}

    // expiresIn default value == 10 days (in seconds)
    init(
        id: UUID? = nil, value: String, userID: UUID, expiresIn: TimeInterval = 864000
    ) {
        self.id = id
        self.value = value
        self.expiresAt = Date().addingTimeInterval(expiresIn)
        self.$user.id = userID
    }

    func isTokenValid() -> Bool {
        return self.expiresAt >= Date()
    }
}
