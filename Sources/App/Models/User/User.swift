// User.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Foundation
import Vapor

enum Role: String, Codable {
    case admin, member
}

final class User: Model, Authenticatable, @unchecked Sendable {
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
    var badgesHistory: [UserBadge]

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        firstName: String,
        lastName: String,
        username: String,
        email: String,
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

    static func fromDTO(_ dto: UserDTO.CreateUser) -> User {
        .init(
            firstName: dto.firstName,
            lastName: dto.lastName,
            username: dto.username,
            email: dto.email,
            role: .member,
            profilePictureURL: dto.profilePictureURL,
            bio: dto.bio,
            phoneNumber: dto.phoneNumber,
            dateOfBirth: dto.dateOfBirth
        )
    }
}
