// UserController.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")

        users.get(use: getAllUsers)
        users.post(use: createUser)

        users.group(":userID") { user in
            user.get(use: getUserInfo)
            user.delete(use: deleteUser)
            user.patch(use: updateUser)
        }
    }

    @Sendable
    func getAllUsers(req: Request) async throws -> [UserDTO.GetUser] {
        try await UserModel.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func createUser(req: Request) async throws -> UserDTO.GetUser {
        let user = try UserModel.fromDTO(req.content.decode(UserDTO.CreateUser.self))

        // TODO: add some two step verification to verify the email belongs to the creator

        try await user.save(on: req.db)
        return user.toDTO()
    }

    @Sendable
    func getUserInfo(req: Request) async throws -> UserDTO.GetUser {
        guard
            let user = try await UserModel.find(
                req.parameters.get("userID", as: UUID.self), on: req.db)
        else {
            throw Abort(.notFound)
        }
        return user.toDTO()
    }

    @Sendable
    func deleteUser(req: Request) async throws -> HTTPStatus {
        guard
            let user = try await UserModel.find(
                req.parameters.get("userID", as: UUID.self), on: req.db)
        else {
            throw Abort(.notFound)
        }

        try await user.deleteDependents(db: req.db, logger: req.logger)
        try await user.delete(on: req.db)
        return .noContent
    }

    @Sendable
    func updateUser(req: Request) async throws -> UserDTO.GetUser {
        let updatedUser = try req.content.decode(UserDTO.UpdateUser.self)
        guard
            let user = try await UserModel.find(
                req.parameters.get("userID", as: UUID.self), on: req.db)
        else {
            throw Abort(.notFound)
        }

        if let firstName = updatedUser.firstName {
            user.firstName = firstName
        }
        if let lastName = updatedUser.lastName {
            user.lastName = lastName
        }
        if let username = updatedUser.username {
            user.username = username
        }
        if let email = updatedUser.email {
            user.email = email
        }
        if let profilePictureURL = updatedUser.profilePictureURL {
            user.profilePictureURL = profilePictureURL
        }
        if let bio = updatedUser.bio {
            user.bio = bio
        }
        if let dateOfBirth = updatedUser.dateOfBirth {
            user.dateOfBirth = dateOfBirth
        }
        if let phoneNumber = updatedUser.phoneNumber {
            user.phoneNumber = phoneNumber
        }

        try await user.update(on: req.db)
        return user.toDTO()
    }
}
