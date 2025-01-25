import Fluent
import Foundation

final class EmailMessageModel: Model, @unchecked Sendable {
    static let schema = "email_messages"

    @ID(key: .id)
    var id: UUID?

    @Enum(key: "message_type")
    var messageType: EmailMessageType

    @Field(key: "message")
    var message: String

    @Field(key: "sent_at")
    var sentAt: Date

    @Parent(key: "sent_to")
    var user: UserModel

    @Field(key: "sent_to_email")
    var sentToEmail: String

    @Field(key: "sent_from_email")
    var sentFromEmail: String

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
        sentTo: UUID,
        sentToEmail: String,
        sentFromEmail: String
    ) {
        self.id = id
        self.messageType = messageType
        self.sentAt = sentAt
        self.sentToEmail = sentToEmail
        self.sentFromEmail = sentFromEmail
        self.$user.id = sentTo
    }
}
