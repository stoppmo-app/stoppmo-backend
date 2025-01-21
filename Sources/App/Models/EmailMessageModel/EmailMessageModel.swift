import Fluent
import Foundation

// TODO: Create migration
// TODO: For migration, create enum. Here is an example enum:
// let role = try await database.enum("user_role")
//     .case("member")
//     .case("admin")
//     .create()

final class EmailMessageModel: Model, @unchecked Sendable {
    static let schema = "email_messages"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "message_type")
    var messageType: EmailMessageType

    @Field(key: "message")
    var message: String

    @Field(key: "sent_at")
    var sentAt: Date

    @Parent(key: "sent_to")
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
        messageType: EmailMessageType,
        sentAt: Date,
        sentTo: UUID
    ) {
        self.id = id
        self.messageType = messageType
        self.sentAt = sentAt
        self.$user.id = sentTo
    }
}
