// AuthenticationController.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

// TODO: Add validations for all models an content objects.

/// Controller for handling all user authentication (login, account creation and registration, logout and two-factor authentication).
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

        auth.post("register", use: register)
        auth.post("register-code", use: sendRegisterCode)

        auth.group(UserBearerAuthenticator(), UserModel.guardMiddleware()) { bearerProtected in
            bearerProtected.post("logout", use: logout)
        }
    }

    /// Send register code to user email, saving the code for code validation when registering and saving email for emails sent rate limit logic in future requests.
    /// - Parameter req: The request object.
    /// - Throws: Throws an error if user account with email passed in payload already exists, emails sent rate limit reached, email did not send, email did not save or auth code did not save.
    /// - Returns: `HTTPStatus` of `.ok` on success.
    @Sendable
    func sendRegisterCode(req: Request) async throws -> HTTPStatus {
        let authService = AuthenticationService(
            database: req.db, client: req.client, logger: req.logger
        )

        let userEmail = try req.content.decode(SendRegisterCodePayload.self).email
        let sendLoginCodeResponse = try await authService.sendRegisterCode(
            email: userEmail
        )

        let authCode = sendLoginCodeResponse.authCode
        let sentEmailMessageID = try sendLoginCodeResponse.savedEmail.requireID()

        try await authService.saveAuthCode(
            code: authCode, userEmail: userEmail, sentEmailMessageID: sentEmailMessageID,
            authCodeType: .register
        )

        return .ok
    }

    /// Validate register code, create user account in database, generate and return bearer token with user data on success.
    /// - Parameter req: The request object.
    /// - Throws: Throws an error if code validation or user creation fails.
    /// - Returns: A `BearerTokenWithUserDTO` containing the user's data and the generated bearer token for authentication.
    @Sendable
    func register(req: Request) async throws -> BearerTokenWithUserDTO {
        let authService = AuthenticationService(
            database: req.db, client: req.client, logger: req.logger
        )
        let user = try UserModel.fromDTO(req.content.decode(UserDTO.CreateUser.self))

        try RegisterAndLoginQueryParameters.validate(query: req)
        let authCode = try req.query.decode(RegisterAndLoginQueryParameters.self).authCode

        return try await authService.register(user: user, authCode: authCode)
    }

    /// Send login code to user email, saving the code for code validation when logging in and saving email for emails sent rate limit logic in future requests.
    /// - Parameter req: The request object.
    /// - Throws: Throws an error if emails sent rate limit reached, email did not send, email did not save or auth code did not save.
    /// - Returns: `HTTPStatus` of `.ok` on success.
    @Sendable
    func sendLoginCode(req: Request) async throws -> HTTPStatus {
        let authService = AuthenticationService(
            database: req.db, client: req.client, logger: req.logger
        )

        let user = try req.auth.require(UserModel.self)
        let userEmail = user.email
        let sendLoginCodeResponse = try await authService.sendLoginCode(
            email: userEmail
        )

        let userID = try user.requireID()

        let authCode = sendLoginCodeResponse.authCode
        let sentEmailMessageID = try sendLoginCodeResponse.savedEmail.requireID()

        try await authService.saveAuthCode(
            code: authCode, userEmail: userEmail, sentEmailMessageID: sentEmailMessageID,
            authCodeType: .login, userID: userID
        )

        return .ok
    }

    /// Validate login code, generate and return bearer token with user data on success.
    /// - Parameter req: The request object.
    /// - Throws: Throws an error if login code validation fails.
    /// - Returns: A `BearerTokenWithUserDTO` containing the user's data and the generated bearer token for authentication.
    @Sendable
    func login(req: Request) async throws -> BearerTokenWithUserDTO {
        let authService = AuthenticationService(
            database: req.db, client: req.client, logger: req.logger
        )

        let user = try req.auth.require(UserModel.self)

        try RegisterAndLoginQueryParameters.validate(query: req)
        let authCode = try req.query.decode(RegisterAndLoginQueryParameters.self).authCode

        return try await authService.login(user: user, authCode: authCode)
    }

    /// Logout user by removing all bearer tokens.
    /// - Parameter req: The request object.
    /// - Throws: Throws an error if removing all bearer tokens on database fails.
    /// - Returns: `HTTPStatus` of `.ok` on success.
    @Sendable
    func logout(req: Request) async throws -> HTTPStatus {
        let authService = AuthenticationService(
            database: req.db, client: req.client, logger: req.logger
        )

        let user = try req.auth.require(UserModel.self)
        let userID = try user.requireID()

        try await authService.logout(user: userID, req: req)
        return .ok
    }
}
