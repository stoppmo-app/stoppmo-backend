// EmailMessageModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Foundation

final class EmailMessageModel: Model, @unchecked Sendable {
    static let schema = "email_messages"

    @ID(key: .id)
    var id: UUID?

    @Enum(key: "message_type")
    var messageType: EmailMessageType

    @Field(key: "subject")
    var subject: String

    @Field(key: "content")
    var content: String

    @Field(key: "sent_at")
    var sentAt: Date

    @OptionalParent(key: "sent_to")
    var user: UserModel?

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
        subject: String,
        content: String,
        sentAt: Date,
        sentTo: UUID?,
        sentToEmail: String,
        sentFromEmail: String
    ) {
        self.id = id
        self.messageType = messageType
        self.subject = subject
        self.content = content
        self.sentAt = sentAt
        self.sentToEmail = sentToEmail
        self.sentFromEmail = sentFromEmail
        if sentTo != nil {
            $user.id = sentTo
        }
    }
}
