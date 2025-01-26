// AuthenticationController.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.group(
            UserBasicAuthenticator(),
            UserModel.guardMiddleware()
        ) { basicProtected in
            basicProtected.post("login", use: login)
            basicProtected.post("login-code", use: sendLoginCode)
        }

        auth.post("register-code", use: sendRegisterCode)
        auth.post("register", use: register)

        auth.group(UserBearerAuthenticator(), UserModel.guardMiddleware()) { bearerProtected in
            bearerProtected.post("logout", use: logout)
        }
    }

    // TODO: Remove `createUser` route in `UserController`

    @Sendable
    func register(req: Request) async throws -> BearerTokenWithUserDTO {
        let authService = AuthenticationService(
            database: req.db, client: req.client, logger: req.logger
        )
        let user = try UserModel.fromDTO(req.content.decode(UserDTO.CreateUser.self))

        try LoginAndRegisterQuery.validate(query: req)
        let authCode = try req.query.decode(LoginAndRegisterQuery.self).authCode

        return try await authService.register(user: user, authCode: authCode)
    }

    @Sendable
    func sendLoginCode(req: Request) async throws -> HTTPStatus {
        let authService = AuthenticationService(
            database: req.db, client: req.client, logger: req.logger
        )

        let user = try req.auth.require(UserModel.self)
        let userEmail = user.email
        let sendLoginCodeResponse = try await authService.sendLoginCode(email: userEmail)

        guard
            let userID = user.id
        else {
            req.logger.error(
                "Failed to get user ID when saving auth code for user with email '\(userEmail)'. This should never happen."
            )
            throw Abort(.internalServerError)
        }
        try await authService.saveAuthCode(
            code: sendLoginCodeResponse.authCode, userEmail: userEmail, userID: userID
        )

        return .ok
    }

    @Sendable
    func sendRegisterCode(req: Request) async throws -> HTTPStatus {
        let authService = AuthenticationService(
            database: req.db, client: req.client, logger: req.logger
        )

        let userEmail = try req.content.decode(SendRegisterCodePayload.self).email
        let sendLoginCodeResponse = try await authService.sendRegisterCode(email: userEmail)

        try await authService.saveAuthCode(
            code: sendLoginCodeResponse.authCode, userEmail: userEmail
        )

        return .ok
    }

    @Sendable
    func login(req: Request) async throws -> BearerTokenWithUserDTO {
        let authService = AuthenticationService(
            database: req.db, client: req.client, logger: req.logger
        )

        let user = try req.auth.require(UserModel.self)

        try LoginAndRegisterQuery.validate(query: req)
        let authCode = try req.query.decode(LoginAndRegisterQuery.self).authCode

        return try await authService.login(user: user, authCode: authCode)
    }

    @Sendable
    func logout(req: Request) async throws -> HTTPStatus {
        let authService = AuthenticationService(
            database: req.db, client: req.client, logger: req.logger
        )

        guard
            let userID = try req.auth.require(UserModel.self).id
        else {
            return .badRequest
        }
        try await authService.logout(user: userID, req: req)
        return .ok
    }
}
