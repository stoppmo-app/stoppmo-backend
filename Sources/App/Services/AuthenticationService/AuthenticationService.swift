// AuthenticationService.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

struct AuthenticationService {
    let database: Database
    let client: Client
    let logger: Logger

    public func sendLoginCode(email: String) async throws
        -> SendAuthCodeResponse
    {
        try await sendAuthCode(email: email, messageType: .authLogin)
    }

    public func sendRegisterCode(email: String) async throws
        -> SendAuthCodeResponse
    {
        try await sendAuthCode(email: email, messageType: .authCreateAccount)
    }

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

    private func sendAuthCode(
        email: String, messageType: EmailMessageType, code: Int? = nil
    )
        async throws
        -> SendAuthCodeResponse
    {
        // Rate limit logic
        let emailRateLimitService = RateLimitService.emailsService(
            .init(database: database, logger: logger)
        )
        let rateLimitResponse = try await emailRateLimitService.authEmailsSent(
            email: email, messageType: messageType
        )

        if rateLimitResponse.limitReached == true {
            throw Abort(
                .custom(
                    code: 429,
                    reasonPhrase: rateLimitResponse.message ?? "Auth Emails Limit Reached"
                )
            )
        }

        // Make sure account doesn't already exist
        if messageType == .authCreateAccount {
            try await handleUserAccountAlreadyExistsWith(email: email)
        }

        let emailClient = ZohoMailClient(database: database, client: client, logger: logger)

        let senderType: EmailSenderType = .authentication

        // 1. Send email
        let authCode = code ?? Int.random(in: 0..<100_000)

        let fromAddress = senderType.getSenderEmail()
        guard
            let authType = messageType.toAuthType()
        else {
            logger.error(
                "Could not convert message type \(messageType.rawValue) to 'AuthCodeType' when sending auth code. This should never happen."
            )
            throw Abort(.internalServerError)
        }

        let sendEmailPayload = try await SendZohoMailEmailPayload.fromTemplate(
            template: .authCode(code: authCode),
            emailParams: .init(
                fromAddress: fromAddress,
                toAddress: email,
                authType: authType
            )
        )

        let sendEmailResponse = try await emailClient.sendEmail(
            senderType: senderType,
            payload: sendEmailPayload,
            messageType: messageType
        )

        // 2. Save email
        let savedEmail = try await emailClient.saveEmail(sendEmailResponse.emailMessage)

        // 3. Return saved email, code and response from sending email using Zoho Mail API
        return .init(
            savedEmail: savedEmail, authCode: authCode,
            sentEmailZohoMailResponse: sendEmailResponse.sentEmailZohoMailResponse
        )
    }

    private func handleUserAccountAlreadyExistsWith(email: String) async throws {
        let user =
            try await UserModel
            .query(on: database)
            .filter(\.$email == email)
            .field(\.$id)
            .first()

        if user != nil {
            throw Abort(
                .custom(
                    code: 409, reasonPhrase: "User already exists with email '\(email)'"
                )
            )
        }
    }

    private func handleAuthCodeExpired(_ authCode: AuthenticationCodeModel) async throws {
        let codeExpired = try await isAuthCodeExpired(authCode)
        let newestCode = try await isAuthCodeTheNewest(authCode)

        if codeExpired == true || newestCode == false {
            throw Abort(.custom(code: 401, reasonPhrase: "Auth Code Expired"))
        }
    }

    func login(user: UserModel, authCode code: Int) async throws -> BearerTokenWithUserDTO {
        let codeType: AuthCodeType = .login
        guard
            let authCode = try await getAuthCode(code, email: user.email, codeType: codeType)
        else {
            throw Abort(.custom(code: 401, reasonPhrase: "Auth Code Invalid"))
        }

        try await handleAuthCodeExpired(authCode)

        // Soft delete all auth codes so that it cannot be used again to login
        // Downside: this might cause problems if multiple devices are trying to login or register at the same time
        let userID = try user.requireID()
        try await softDeleteAllAuthCodes(id: userID)

        let token = generateBearerToken(id: userID)
        try await token.save(on: database)

        return .init(token: token.value, user: user.toDTO())
    }

    func register(user: UserModel, authCode code: Int) async throws -> BearerTokenWithUserDTO {
        let userEmail = user.email
        try await handleUserAccountAlreadyExistsWith(email: userEmail)

        let codeType: AuthCodeType = .register

        guard
            let authCode = try await getAuthCode(code, email: userEmail, codeType: codeType)
        else {
            throw Abort(.custom(code: 401, reasonPhrase: "Auth Code Invalid"))
        }

        try await handleAuthCodeExpired(authCode)

        // Save user to generate `id`
        try await user.save(on: database)
        let userID = try user.requireID()

        // Soft delete all auth codes to avoid register attempts with old auth codes
        // Downside: this might cause problems if multiple devices are trying to login or register at the same time
        try await softDeleteAllRegisterAuthCodes(email: user.email)

        let token = generateBearerToken(id: userID)
        try await token.save(on: database)

        return .init(token: token.value, user: user.toDTO())
    }

    private func isAuthCodeTheNewest(_ authCode: AuthenticationCodeModel) async throws -> Bool {
        let newerCodes =
            try await AuthenticationCodeModel
            .query(on: database)
            .filter(\.$expiresAt > authCode.expiresAt)
            .all()

        return newerCodes.count == 0
    }

    private func softDeleteAllAuthCodes(id userID: UUID)
        async throws
    {
        try await AuthenticationCodeModel
            .query(on: database)
            .filter(\.$user.$id == userID)
            .delete()
    }

    private func softDeleteAllRegisterAuthCodes(email userEmail: String)
        async throws
    {
        try await AuthenticationCodeModel
            .query(on: database)
            .filter(\.$email == userEmail)
            .filter(\.$codeType == AuthCodeType.register)
            .delete()
    }

    private func getAuthCode(_ code: Int, email: String, codeType: AuthCodeType) async throws
        -> AuthenticationCodeModel?
    {
        let code =
            try await AuthenticationCodeModel
            .query(on: database)
            .filter(\.$value == code)
            .filter(\.$email == email)
            .filter(\.$codeType == codeType)  // make sure the generated code was created for the right auth type
            .first()
        return code
    }

    private func isAuthCodeExpired(_ code: AuthenticationCodeModel) async throws -> Bool {
        code.expiresAt <= Date()
    }

    func logout(user userID: UUID, req: Request) async throws {
        try await removeOldBearerTokens(for: userID)
        req.auth.logout(UserModel.self)
    }

    func generateBearerToken(id userID: UUID) -> UserTokenModel {
        .init(
            value: [UInt8].random(count: 16).base64,
            userID: userID
        )
    }

    func getUserFromBearerAuthorization(_ bearer: BearerAuthorization) async throws -> UserModel {
        // 1. Get token from db
        let token = try await getBearerToken(bearer.token)

        // 2. Validate token
        if token.isTokenValid() == false {
            throw Abort(.custom(code: 401, reasonPhrase: "Token Expired"))
        }

        // 3. Return user
        return try await token.$user.get(on: database)
    }

    func getUserFromBasicAuthorization(_ basic: BasicAuthorization) async throws -> UserModel {
        // 1. Get user from db
        guard
            let user =
                try await UserModel
                .query(on: database)
                .filter(\.$username, .equal, basic.username)
                .first()
        else {
            throw Abort(.notFound)
        }

        // 2. Verify password
        let passwordCorrect = try Bcrypt.verify(basic.password, created: user.passwordHash)

        // 3. Return user
        if passwordCorrect == true {
            return user
        } else {
            throw Abort(.unauthorized)
        }
    }

    func getBearerToken(_ token: String) async throws -> UserTokenModel {
        guard
            let userToken =
                try await UserTokenModel
                .query(on: database)
                .filter(\.$value, .equal, token)
                .first()
        else {
            throw Abort(.custom(code: 401, reasonPhrase: "Token Not Found"))
        }
        return userToken
    }

    func removeOldBearerTokens(for userID: UUID) async throws {
        let tokens =
            try await UserTokenModel
            .query(on: database)
            .filter(\.$user.$id, .equal, userID)
            .all()

        for token in tokens {
            try await token.delete(on: database)
        }
    }
}
