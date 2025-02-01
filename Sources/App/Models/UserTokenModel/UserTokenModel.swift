// UserTokenModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

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
        id: UUID? = nil, value: String, userID: UUID, expiresIn: TimeInterval = 864_000
    ) {
        self.id = id
        self.value = value
        expiresAt = Date().addingTimeInterval(expiresIn)
        $user.id = userID
    }

    public func isTokenValid() -> Bool {
        expiresAt >= Date()
    }

    public func validOrThrow() throws {
        if self.isTokenValid() == false {
            throw Abort(.custom(code: 401, reasonPhrase: "Bearer token expired."))
        }
    }
}
