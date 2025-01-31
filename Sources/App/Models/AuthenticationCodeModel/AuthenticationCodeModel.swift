// AuthenticationCodeModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

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

    @Enum(key: "code_type")
    var codeType: AuthCodeType

    @OptionalParent(key: "user_id")
    var user: UserModel?

    @Parent(key: "email_message_id")
    var emailMessage: EmailMessageModel

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
        emailMessageID: UUID,
        codeType: AuthCodeType,
        userID: UUID? = nil
    ) {
        self.id = id
        self.value = value
        self.email = email
        self.codeType = codeType
        expiresAt = Date().addingTimeInterval(expiresIn)
        $user.id = userID
        $emailMessage.id = emailMessageID
    }
}
