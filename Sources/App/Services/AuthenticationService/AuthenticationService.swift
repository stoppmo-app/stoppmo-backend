// AuthenticationService.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

// TODO: add rate limit logic for the amount of login and register attempts a user can make to avoid brute-forcing login by spamming
// routes with authentication codes (bypass TFA, which is a security risk if a user accidentally leaked email and password)

// TODO: Evaluate whether it is even necessary to implement this: 👇
// TODO: Have different authentication codes specifically for a specific device, to avoid soft deleting codes that another device generated
// (which can cause problems logging into app on different devices at the same time).

/// Service that provides all authentication logic as methods (login, account creation and registration, logout and two-factor authentication).
struct AuthenticationService {
    let database: Database
    let client: Client
    let logger: Logger

    /// Send login code email to user email and save sent email to database.
    /// - Parameter email: User email to send code to.
    /// - Throws: Throws an error if user reached email sent rate limit or email did not send successfully.
    /// - Returns: A `SendAuthCodeResponse` containing data like the email sent, auth code used and response from email sent using email client.
    public func sendLoginCode(email: String) async throws
        -> SendAuthCodeResponse
    {
        try await sendAuthCode(email: email, authCodeType: .login)
    }

    /// Send register code email to user email and save sent email to database.
    /// - Parameter email: User email to send code to.
    /// - Throws: Throws an error if account with email already exists, user reached email sent rate limit or email did not send successfully.
    /// - Returns: A `SendAuthCodeResponse` containing data like the email sent, auth code used and response from email sent using email client.
    public func sendRegisterCode(email: String) async throws
        -> SendAuthCodeResponse
    {
        try await sendAuthCode(email: email, authCodeType: .register)
    }

    /// Save authentication code to database.
    /// - Parameters:
    ///   - code: Authentication code sent in email.
    ///   - userEmail: Email the code was sent to.
    ///   - sentEmailMessageID: Email message model ID.
    ///   - authCodeType: Code type (for register or login).
    ///   - userID: ID of user this code was sent to.
    ///
    /// - Throws: Throws an error if code fails to save to database.
    public func saveAuthCode(
        code: Int, userEmail: String, sentEmailMessageID: UUID, authCodeType: AuthCodeType,
        userID: UUID? = nil
    )
        async throws
    {
        let authCode = AuthenticationCodeModel(
            value: code, email: userEmail, emailMessageID: sentEmailMessageID,
            codeType: authCodeType, userID: userID
        )
        try await authCode.save(on: database)
    }

    /// Send authentication code email to user email and save email to database.
    /// - Parameters:
    ///   - email: User email to send email to.
    ///   - authCodeType: Type of authentication the code will be used for (register or login).
    ///   - code: Code to send inside the email.
    ///
    /// - Throws:
    /// - Throws: Throws an error if `authCodeType` is `register` and account with email already exists, user reached email sent rate limit or email did not send successfully.
    /// - Returns: A `SendAuthCodeResponse` containing data like the email sent, auth code used and response from email sent using email client.
    private func sendAuthCode(
        email: String, authCodeType: AuthCodeType, code: Int? = nil
    )
        async throws
        -> SendAuthCodeResponse
    {
        let emailRateLimitService = RateLimitService.emailsService(
            .init(database: database, logger: logger)
        )
        let emailMessageType = try authCodeType.toEmailMessageType(logger: logger)
        try await emailRateLimitService.authEmailsSent(
            email: email, messageType: emailMessageType
        )

        if authCodeType == .register {
            try await validateUniqueEmail(email: email)
        }

        let emailClient = ZohoMailClient(database: database, client: client, logger: logger)
        let senderType: EmailSenderType = .authentication
        let authCode = code ?? Int.random(in: 0..<100_000)

        let fromAddress = senderType.getSenderEmail()
        let sendEmailPayload = try await SendEmailPayload.fromTemplate(
            template: .authCode(code: authCode),
            fromAddress: fromAddress,
            toAddress: email,
            authType: authCodeType
        )

        let sendEmailResponse = try await emailClient.sendEmail(
            senderType: senderType,
            payload: sendEmailPayload,
            messageType: emailMessageType
        )
        let savedEmail = try await emailClient.saveEmail(sendEmailResponse.emailMessage)
        return .init(
            savedEmail: savedEmail, authCode: authCode,
            sentZohoMailEmailResponse: sendEmailResponse.sentZohoMailResponse
        )
    }

    /// Validate no user exists with a specific email.
    /// - Parameter email: Email to validate.
    /// - Throws: An error if user exists with email.
    private func validateUniqueEmail(email: String) async throws {
        if try await UserModel
            .query(on: database)
            .filter(\.$email == email)
            .count() > 0
        {

            throw Abort(
                .custom(
                    code: 409, reasonPhrase: "User already exists with email '\(email)'."
                )
            )
        }
    }

    /// Validates whether authentication code is valid for login in or register.
    /// - Parameter authCode: Authentication code to validate.
    /// - Throws: Throws an error if code is expired or a new code was generated
    private func validateAuthCode(_ authCode: AuthenticationCodeModel)
        async throws
    {
        let codeExpired = isAuthCodeExpired(authCode.expiresAt)
        let newestCode = try await isAuthCodeTheLatest(authCode)

        if codeExpired == true || newestCode == false {
            throw Abort(.custom(code: 401, reasonPhrase: "Authentication code expired."))
        }
    }

    /// Validate login code, login user by generating and return bearer token with user data.
    /// - Parameters:
    ///   - user: User who wants to login.
    ///   - code: Authentication code sent to user email.
    ///
    /// - Throws: Throws an error when code is invalid or token did not save successfully.
    /// - Returns: A `BearerTokenWithUserDTO` containing the user's data and the generated bearer token for authentication.
    public func login(user: UserModel, authCode code: Int) async throws -> BearerTokenWithUserDTO {
        let authCode = try await getAuthCode(code, email: user.email, codeType: .login)
        try await validateAuthCode(authCode)

        let userID = try user.requireID()
        try await deleteAllAuthCodes(id: userID)

        let token = generateBearerToken(id: userID)
        try await token.save(on: database)

        return .init(token: token.value, user: user.toDTO())
    }

    /// Validate register code, save user to database, register user by generating and returning bearer token with user data.
    /// - Parameters:
    ///   - user: User who wants to login.
    ///   - code: Authentication code sent to user email.
    ///
    /// - Throws: Throws an error when code is invalid or token did not save successfully.
    /// - Returns: A `BearerTokenWithUserDTO` containing the user's data and the generated bearer token for authentication.
    public func register(user: UserModel, authCode code: Int) async throws -> BearerTokenWithUserDTO
    {
        let userEmail = user.email
        try await validateUniqueEmail(email: userEmail)

        let authCode = try await getAuthCode(code, email: userEmail, codeType: .register)
        try await validateAuthCode(authCode)

        try await user.save(on: database)
        let userID = try user.requireID()

        try await deleteAllRegisterAuthCodes(email: user.email)

        let token = generateBearerToken(id: userID)
        try await token.save(on: database)

        return .init(token: token.value, user: user.toDTO())
    }

    /// Helper method that checks if authentication code is expired.
    /// - Parameter expiresAt: Code expires at date.
    /// - Returns: True if code is expired, false if not.
    private func isAuthCodeExpired(_ expiresAt: Date) -> Bool {
        Date() >= expiresAt
    }

    /// Helper method that checks if authentication code was the latest one sent.
    /// - Parameter authCode:
    /// - Throws: Throws an error if database query fails.
    /// - Returns: True if code is the latest, false if not.
    private func isAuthCodeTheLatest(_ authCode: AuthenticationCodeModel)
        async throws -> Bool
    {
        // No need to validate `AuthCodeType`.
        // User cannot send:
        // - login code when account doesn't exist (basic authentication will fail).
        // - register code when an account already exists.
        return try await AuthenticationCodeModel
            .query(on: database)
            .filter(\.$expiresAt > authCode.expiresAt)
            .count() == 0
    }

    /// Delete all authentication codes for a specific user.
    /// - Parameter userID: User ID.
    /// - Throws: Throws an error if code deletion on database fails.
    private func deleteAllAuthCodes(id userID: UUID)
        async throws
    {
        try await AuthenticationCodeModel
            .query(on: database)
            .filter(\.$user.$id == userID)
            .delete()
    }

    /// Delete all register authentication codes for a specific user.
    /// - Parameter userEmail: User email.
    /// - Throws: Throws an error if code deletion on database fails.
    private func deleteAllRegisterAuthCodes(email userEmail: String)
        async throws
    {
        try await AuthenticationCodeModel
            .query(on: database)
            .filter(\.$email == userEmail)
            .filter(\.$codeType == AuthCodeType.register)
            .delete()
    }

    /// Get authentication code from database.
    /// - Parameters:
    ///   - code: Code number.
    ///   - email: Email this code was sent to.
    ///   - codeType: Authentication type this code this code was meant for (register or login).
    ///
    /// - Throws: Throws an error when code does not exist or issue finding it in database.
    /// - Returns: A`AuthenticationCodeModel`, the authentication code.
    private func getAuthCode(_ code: Int, email: String, codeType: AuthCodeType)
        async throws -> AuthenticationCodeModel
    {
        guard
            let code =
                try await AuthenticationCodeModel
                .query(on: database)
                .filter(\.$value == code)
                .filter(\.$email == email)
                .filter(\.$codeType == codeType)  // make sure the generated code was created for the right auth type
                .first()
        else {
            throw Abort(.custom(code: 404, reasonPhrase: "Authentication code not found."))
        }
        return code
    }

    /// Logout user by removing all bearer tokens.
    /// - Parameters:
    ///   - userID: ID of user to logout.
    ///   - req: Request object to logout.
    ///
    /// - Throws:
    public func logout(user userID: UUID, req: Request) async throws {
        try await removeOldBearerTokens(for: userID)
        req.auth.logout(UserModel.self)
    }

    /// Generate a `UserToken` with a random value.
    /// - Parameter userID: ID of the user the token is for.
    /// - Returns: A `UserTokenModel`, the generated bearer token.
    public func generateBearerToken(id userID: UUID) -> UserTokenModel {
        .init(
            value: [UInt8].random(count: 16).base64,
            userID: userID
        )
    }

    public func getUserFromBearerAuthorization(_ bearer: BearerAuthorization) async throws
        -> UserModel
    {
        let token = try await getBearerToken(bearer.token)
        if token.isTokenValid() == false {
            throw Abort(.custom(code: 401, reasonPhrase: "Token Expired"))
        }
        return try await token.$user.get(on: database)
    }

    public func getUserFromBasicAuthorization(_ basic: BasicAuthorization) async throws -> UserModel
    {
        guard
            let user =
                try await UserModel
                .query(on: database)
                .filter(\.$username == basic.username)
                .first()
        else {
            throw Abort(.notFound)
        }
        let passwordCorrect = try Bcrypt.verify(basic.password, created: user.passwordHash)
        if passwordCorrect == true {
            return user
        } else {
            throw Abort(.unauthorized)
        }
    }

    private func getBearerToken(_ token: String) async throws -> UserTokenModel {
        guard
            let userToken =
                try await UserTokenModel
                .query(on: database)
                .filter(\.$value == token)
                .first()
        else {
            throw Abort(.custom(code: 401, reasonPhrase: "Token Not Found"))
        }
        return userToken
    }

    private func removeOldBearerTokens(for userID: UUID) async throws {
        let tokens =
            try await UserTokenModel
            .query(on: database)
            .filter(\.$user.$id == userID)
            .all()

        for token in tokens {
            try await token.delete(on: database)
        }
    }
}
