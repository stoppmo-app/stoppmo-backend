// AuthenticationService.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

// TODO: add rate limit logic for the amount of login and register attempts a user can make to avoid brute-forcing login by spamming
// routes with authentication codes (bypass TFA, which is a security risk if a user accidentally leaked email and password).

// TODO: Add useful logging statements, ensure error handling is useful and consistent throughout the module.
// TODO: Evaluate whether it is even necessary to implement this: 👇.
// TODO: Have different authentication codes specifically for a specific device, to avoid soft deleting codes that another device generated
// (which can cause problems logging into app on different devices at the same time).

/// Service that provides all authentication logic as methods (login, account creation and registration, logout and two-factor authentication).
struct AuthenticationService {
    let database: Database
    let client: Client
    let logger: Logger

    /// Send login code email to user email and save sent email to database.
    /// - Parameter email: User email to send code to.
    /// - Throws: Throws an error if user reached email sent rate limit, email did not send or save.
    /// - Returns: A `SendAuthCodeResponse` containing data like the email sent, auth code used and response from email sent using email client.
    public func sendLoginCode(email: String) async throws
        -> SendAuthCodeResponse
    {
        try await sendAuthCode(email: email, authCodeType: .login)
    }

    /// Send register code email to user email and save sent email to database.
    /// - Parameter email: User email to send code to.
    /// - Throws: Throws an error if account with email already exists, user reached email sent rate limit, email did not send or save.
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
    /// - Throws: Throws an error if `authCodeType` is `register` and account with email already exists, user reached email sent rate limit, email did not send or save.
    /// - Returns: A `SendAuthCodeResponse` containing data like the email sent, auth code used and response from email sent using email client.
    private func sendAuthCode(
        email: String, authCodeType: AuthCodeType, code: Int? = nil
    )
        async throws
        -> SendAuthCodeResponse
    {
        let emailMessageType = try authCodeType.toEmailMessageType(logger: logger)
        try await canSendAuthEmailOrThrow(email: email, emailMessageType: emailMessageType)

        try await validateEmailForRegister(authCodeType: authCodeType, email: email)
        return try await sendAuthCodeEmail(
            code: code, email: email, authCodeType: authCodeType, emailMessageType: emailMessageType
        )
    }

    /// A helper method that gets first gets auth email data, then send and save the email.
    /// - Parameters:
    ///   - code: Auth code number.
    ///   - email: Email address auth code email will be sent to.
    ///   - authCodeType: Authentication code type (register or login).
    ///   - emailMessageType: Type of email user wants to receive.
    ///
    /// - Throws: Throws an erorr when email did not send or save.
    /// - Returns: A `SendAuthCodeResponse` containing data like the email sent, auth code used and response from email sent using email client.
    private func sendAuthCodeEmail(
        code: Int?, email: String, authCodeType: AuthCodeType, emailMessageType: EmailMessageType
    ) async throws -> SendAuthCodeResponse {
        let data = getSendAuthCodeEmailData(
            code: code, email: email, authCodeType: authCodeType)
        return try await sendAuthCodeEmailFromData(data: data, emailMessageType: emailMessageType)
    }

    /// Helper method that sends and save email to user using `ZohoMailClient` and `SendAuthCodeEmailData` as input.
    /// - Parameters:
    ///   - data: Data required to send and save
    ///   - emailMessageType: Type of email message (`authCreateAccount` for register and `authLogin` for login)
    ///
    /// - Throws: Throws an erorr when email did not send or save.
    /// - Returns: A `SendAuthCodeResponse` containing data like the email sent, auth code used and response from email sent using email client.
    private func sendAuthCodeEmailFromData(
        data: SendAuthCodeEmailData, emailMessageType: EmailMessageType
    ) async throws
        -> SendAuthCodeResponse
    {
        let emailClient = ZohoMailClient(database: database, client: client, logger: logger)
        let sendEmailResponse = try await emailClient.sendEmail(
            senderType: .authentication,
            payload: data.sendEmailPayload,
            messageType: emailMessageType
        )
        let savedEmail = try await emailClient.saveEmail(sendEmailResponse.emailMessage)
        return .init(
            savedEmail: savedEmail, authCode: data.authCode,
            sentZohoMailEmailResponse: sendEmailResponse.sentZohoMailResponse
        )
    }

    /// Helper method that gets data for send auth code email.
    /// - Parameters:
    ///   - code: Auth code number.
    ///   - email: Email address auth code email will be sent to.
    ///   - authCodeType: Authentication code type (register or login).
    ///
    /// - Returns: A `SendAuthCodeEmailData`, an object that contains all data necessary for sending email to user.
    private func getSendAuthCodeEmailData(code: Int?, email: String, authCodeType: AuthCodeType)
        -> SendAuthCodeEmailData

    {
        let senderType: EmailSenderType = .authentication
        let authCode = code ?? Int.random(in: 0..<100_000)

        let fromAddress = senderType.getSenderEmail()
        let payload = SendEmailPayload.fromTemplate(
            template: .authCode(code: authCode),
            fromAddress: fromAddress,
            toAddress: email,
            authType: authCodeType
        )
        return .init(sendEmailPayload: payload, authCode: authCode, senderType: senderType)
    }

    /// Helper method that validates no user exists with a specific email when sending auth code for register, throwing an error on fail.
    /// - Parameters:
    ///   - authCodeType:
    ///   - email:
    ///
    /// - Throws:
    private func validateEmailForRegister(authCodeType: AuthCodeType, email: String)
        async throws
    {
        if authCodeType == .register {
            try await uniqueEmailOrThrow(email: email)
        }

    }

    /// A helper method that checks if user with email `email` can receive an auth email or throw an error if not.
    /// - Parameters:
    ///   - email: Email of user.
    ///   - emailMessageType: Type of email user wants to receive.
    ///
    /// - Throws: Throws an error if user reached rate limit.
    private func canSendAuthEmailOrThrow(email: String, emailMessageType: EmailMessageType)
        async throws
    {
        let emailRateLimitService = RateLimitService.emailsService(
            .init(database: database, logger: logger)
        )
        try await emailRateLimitService.authEmailsSent(
            email: email, messageType: emailMessageType
        )
    }

    /// No user exists with a specific email or throw an error.
    /// - Parameter email: Email to validate.
    /// - Throws: An error if user exists with email.
    private func uniqueEmailOrThrow(email: String) async throws {
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

    /// Authentication code is valid for login in or register or throw an error.
    /// - Parameter authCode: Authentication code to validate.
    /// - Throws: Throws an error if database query fails when calling `isAuthCodeLatest`, code is expired or a new code was generated.
    private func authCodeValidOrThrow(_ authCode: AuthenticationCodeModel)
        async throws
    {
        let codeExpired = isAuthCodeExpired(authCode.expiresAt)
        let newestCode = try await isAuthCodeTheLatest(authCode)

        if codeExpired == true || newestCode == false {
            throw Abort(.custom(code: 401, reasonPhrase: "Authentication code expired."))
        }
    }

    /// Validate authentication code, save user on register, authenticate user by generating and returning token with user data.
    /// - Parameters:
    ///   - user: User who wants to login.
    ///   - code: Authentication code sent to user email.
    ///   - codeType: Authentication type (register or login)
    ///
    /// - Throws: Throws an error when code is invalid or token did not save successfully.
    /// - Returns: A `BearerTokenWithUserDTO` containing the user's data and the generated bearer token for authentication.
    private func authenticate(
        user: UserModel, code: Int, codeType: AuthCodeType
    )
        async throws -> BearerTokenWithUserDTO
    {
        let userEmail = user.email
        let authCode = try await getAuthCodeOrThrow(code, email: userEmail, codeType: .register)
        try await authCodeValidOrThrow(authCode)

        var userID: UUID
        if codeType == .register {
            try await user.save(on: database)
            userID = try user.requireID()
            try await deleteAllRegisterAuthCodes(email: userEmail)
        } else {
            userID = try user.requireID()
            try await deleteAllAuthCodes(id: userID)
        }

        let token = generateBearerToken(id: userID)
        try await token.save(on: database)

        return .init(token: token.value, user: user.toDTO())
    }

    /// Validate login code, login user by generating and return bearer token with user data.
    /// - Parameters:
    ///   - user: User who wants to login.
    ///   - code: Authentication code sent to user email.
    ///
    /// - Throws: Throws an error when code is invalid or token did not save successfully.
    /// - Returns: A `BearerTokenWithUserDTO` containing the user's data and the generated bearer token for authentication.
    public func login(user: UserModel, authCode code: Int) async throws -> BearerTokenWithUserDTO {
        return try await authenticate(user: user, code: code, codeType: .login)
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
        try await uniqueEmailOrThrow(email: userEmail)

        return try await authenticate(user: user, code: code, codeType: .register)
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

    /// Get authentication code from database or throw an error.
    /// - Parameters:
    ///   - code: Code number.
    ///   - email: Email this code was sent to.
    ///   - codeType: Authentication type this code this code was meant for (register or login).
    ///
    /// - Throws: Throws an error when code does not exist or issue finding it in database.
    /// - Returns: A`AuthenticationCodeModel`, the authentication code.
    private func getAuthCodeOrThrow(_ code: Int, email: String, codeType: AuthCodeType)
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
        try await deleteAllBearerTokens(for: userID)
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

    /// Get `UserModel` object from `BearerAuthorization`, an object found in `UserBearerAuthenticator`.
    /// - Parameter bearer: Bearer token object found from request in `UserBearerAuthenticator`middleware.
    /// - Throws: Throws an error when token is expired.
    /// - Returns: A `UserModel` - the user object, the owner of the bearer token.
    public func getUserFromBearerAuthorization(_ bearer: BearerAuthorization) async throws
        -> UserModel
    {
        let token = try await getBearerToken(bearer.token)
        try token.validOrThrow()
        return try await token.$user.get(on: database)
    }

    /// Get `UserModel` object from `BasicAuthorization`, an object found in `UserBasicAuthenticator`.
    /// - Parameter basic: Basic object containing username and password found from request in `UserBasicAuthenticator` middleware.
    /// - Throws: Throws an error when account with username does not exist or when password is incorrect.
    /// - Returns: A `UserModel` - the user whose username and password matches with email and password in `basic` parameter.
    public func getUserFromBasicAuthorization(_ basic: BasicAuthorization) async throws -> UserModel
    {
        // Avoid being too descriptive, use generic error messages to avoid exposing too much information in database.
        let errorMessageOnInvalidCredentials =
            "Incorrect username and/or password. Verify credentials and try again."
        let user = try await getUserFromUsernameOrThrow(
            basic.username, userNotFoundErrorMessage: errorMessageOnInvalidCredentials)
        if try Bcrypt.verify(basic.password, created: user.passwordHash) {
            return user
        } else {
            throw Abort(
                .custom(
                    code: 401,
                    reasonPhrase: errorMessageOnInvalidCredentials
                )
            )
        }
    }

    /// Get `UserModel` object from passed in `username` parameter or throw an error.
    /// - Parameters:
    ///   - username: Username of user.
    ///   - userNotFoundErrorMessage: `reasonPhrase` on abort error when user with `username` does not exist in database.
    ///
    /// - Throws: Throws an error when user with `username` does not exist in database.
    /// - Returns: A `UserModel`, the user object where the username matches the passed in `username`.
    private func getUserFromUsernameOrThrow(
        _ username: String, userNotFoundErrorMessage: String
    ) async throws -> UserModel {
        guard
            let user =
                try await UserModel
                .query(on: database)
                .filter(\.$username == username)
                .first()
        else {
            throw Abort(.custom(code: 404, reasonPhrase: userNotFoundErrorMessage))
        }
        return user
    }

    /// Get `UserTokenModel` from bearer token string.
    /// - Parameter token: Token string.
    /// - Throws: Throws an error when token does not exist in database.
    /// - Returns: A `UserToken`, the bearer token object where `token` matches the object value.
    private func getBearerToken(_ token: String) async throws -> UserTokenModel {
        guard
            let userToken =
                try await UserTokenModel
                .query(on: database)
                .filter(\.$value == token)
                .first()
        else {
            throw Abort(.custom(code: 404, reasonPhrase: "Bearer token not found."))
        }
        return userToken
    }

    /// Delete all bearer tokens in database for a specific user.
    /// - Parameter userID: ID of user.
    /// - Throws: Throws an error when there is a problem querying and deleting all tokens.
    private func deleteAllBearerTokens(for userID: UUID) async throws {
        try await UserTokenModel
            .query(on: database)
            .filter(\.$user.$id == userID)
            .delete()
    }
}
