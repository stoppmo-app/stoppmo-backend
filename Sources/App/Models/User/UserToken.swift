import Fluent
import Vapor

final class UserToken: Model, Content, @unchecked Sendable  {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Field(key: "expires_at")
    var expiresAt: Date

    @Parent(key: "user_id")
    var user: User

    init() {}

    // expiresIn defalut value == 10 days (in seconds)
    init(id: UUID? = nil, value: String, userID: User.IDValue, expiresIn: TimeInterval = 864000) {
        self.id = id
        self.value = value
        self.expiresAt = Date().addingTimeInterval(expiresIn)
        self.$user.id = userID
    }
}

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user

    var isValid: Bool {
        true
    }
}
