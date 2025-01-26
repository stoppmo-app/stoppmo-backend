// UserModel.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Foundation
import Vapor

enum Role: String, Codable {
    case admin, member
}

final class UserModel: Model, Authenticatable, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @Field(key: "username")
    var username: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Enum(key: "role")
    var role: Role

    @Field(key: "profile_picture_url")
    var profilePictureURL: String

    @Field(key: "bio")
    var bio: String

    @Field(key: "phone_number")
    var phoneNumber: String

    @Field(key: "date_of_birth")
    var dateOfBirth: Date

    @Children(for: \.$user)
    var badgesHistory: [UserBadgeModel]

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        firstName: String,
        lastName: String,
        username: String,
        email: String,
        passwordHash: String,
        role: Role,
        profilePictureURL: String,
        bio: String,
        phoneNumber: String,
        dateOfBirth: Date
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.role = role
        self.profilePictureURL = profilePictureURL
        self.bio = bio
        self.phoneNumber = phoneNumber
        self.dateOfBirth = dateOfBirth
    }

    func toDTO() -> UserDTO.GetUser {
        .init(
            id: id,
            firstName: firstName,
            lastName: lastName,
            username: username,
            profilePictureURL: profilePictureURL,
            bio: bio,
            dateOfBirth: dateOfBirth
        )
    }

    static func fromDTO(_ dto: UserDTO.CreateUser) throws -> UserModel {
        try .init(
            firstName: dto.firstName,
            lastName: dto.lastName,
            username: dto.username,
            email: dto.email,
            passwordHash: Bcrypt.hash(dto.password),
            role: .member,
            profilePictureURL: dto.profilePictureURL,
            bio: dto.bio,
            phoneNumber: dto.phoneNumber,
            dateOfBirth: dto.dateOfBirth
        )
    }

    func deleteDependents(db: Database, logger: Logger) async throws {
        let id = try requireID()
        logger.info("Deleting all auth codes for user with ID '\(id)'.")
        try await AuthenticationCodeModel
            .query(on: db)
            .filter(\.$user.$id == id)
            .delete()

        logger.info("Deleting all badges for user with ID '\(id)'.")
        try await UserBadgeModel
            .query(on: db)
            .filter(\.$user.$id == id)
            .delete()

        logger.info("Deleting all email messages for user with ID '\(id)'.")
        try await EmailMessageModel
            .query(on: db)
            .filter(\.$user.$id == id)
            .delete()

        try await EmailMessageModel
            .query(on: db)
            .filter(\.$sentToEmail == email)
            .delete()

        logger.info("Deleting all tokens for user with ID '\(id)'.")
        try await UserTokenModel
            .query(on: db)
            .filter(\.$user.$id == id)
            .delete()
    }
}
