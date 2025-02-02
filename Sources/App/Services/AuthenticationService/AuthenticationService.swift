// AuthenticationService.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

// TODO: add rate limit logic for the amount of login and register attempts a user can make to avoid brute-forcing login by spamming
// routes with authentication codes (bypass TFA, which is a security risk if a user accidentally leaked email and password).

// TODO: Go through all code and make sure there aren't any logical mistakes, make sure errors doesn't expose unnecessary information nor
// ignores necessary information by just throwing an `internalServerError` when it shouldn't.

// TODO: Make sure errors are included in catch block logs.

// TODO: Add useful logging statements, ensure error handling is useful and consistent throughout the module.
// TODO: refactor all logging statements to use JSON for metadata instead of logging it as one line (easier to read).
// TODO: Look at how brother is handling errors and logs in the main methods and helper methods, and the relation between them.

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
        logger.info(
            "Save authentication code started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "code": .stringConvertible(code),
                "userEmail": .string(userEmail),
                "authCodeType": .string(authCodeType.rawValue),
            ]
        )

        let authCode = AuthenticationCodeModel(
            value: code, email: userEmail, emailMessageID: sentEmailMessageID,
            codeType: authCodeType, userID: userID
        )

        do {
            try await authCode.save(on: database)
        } catch {
            logger.error(
                "Save authentication code failed: error saving code to database.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "code": .stringConvertible(code),
                    "userEmail": .string(userEmail),
                    "authCodeType": .string(authCodeType.rawValue),
                ]
            )
            throw Abort(.internalServerError)
        }

        logger.info(
            "Save authentication code success.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "authCodeModel": .stringConvertible(authCode),
            ]
        )
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
        // TODO: change errors for helper methods to not throw generic errors,
        // but to include a `reasonPhrase` (so that the error description for the logs in this function
        // is more descriptive, not relying on just tracking the logs for this request).
        logger.info(
            "Send authentication code to user started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "email": .string(email),
                "authCodeType": .string(authCodeType.rawValue),
            ]
        )

        var emailMessageType: EmailMessageType
        do {
            emailMessageType = try authCodeType.toEmailMessageType(logger: logger)
            logger.info(
                "Got email message type from authentication code type successfully.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "emailMessageType": .string(emailMessageType.rawValue),
                    "email": .string(email),
                    "authCodeType": .string(authCodeType.rawValue),
                ]
            )
        } catch {
            logger.error(
                "Send authentication code to user email failed: could not convert auth code type to email message type.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "email": .string(email),
                    "authCodeType": .string(authCodeType.rawValue),
                ]
            )
            throw Abort(.internalServerError)
        }

        do {
            try await canSendAuthEmailOrThrow(email: email, emailMessageType: emailMessageType)
            logger.info(
                "User may receive authentication code email - rate limit not reached.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "email": .string(email),
                    "emailMessageType": .string(emailMessageType.rawValue),
                    "authCodeType": .string(authCodeType.rawValue),
                ]
            )
        } catch {
            logger.error(
                "Send authentication code to user email failed: rate limit restrictions does not allow user to get email.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "email": .string(email),
                    "emailMessageType": .string(emailMessageType.rawValue),
                    "authCodeType": .string(authCodeType.rawValue),
                ]
            )
            throw Abort(.tooManyRequests)
        }

        do {
            try await validateEmailForRegister(authCodeType: authCodeType, email: email)
        } catch {
            logger.info(
                "Send authentication code to user email failed: email not valid for account registration.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "email": .string(email),
                    "emailMessageType": .string(emailMessageType.rawValue),
                    "authCodeType": .string(authCodeType.rawValue),
                ]
            )
            throw error
        }

        do {
            let sendAndSaveEmailResponse = try await sendAndSaveAuthCodeEmail(
                code: code, email: email, authCodeType: authCodeType,
                emailMessageType: emailMessageType
            )
            logger.info(
                "Send and save authentication code to user email success.",
                metadata: [
                    "sendAndSaveEmailResponse": .string("\(sendAndSaveEmailResponse)")
                ]
            )
            return sendAndSaveEmailResponse
        } catch {
            logger.error(
                "Send authentication code to user email failed: error sending and saving email to user using email client.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "email": .string(email),
                    "emailMessageType": .string(emailMessageType.rawValue),
                    "authCodeType": .string(authCodeType.rawValue),
                ]
            )
            throw Abort(.internalServerError)
        }
    }

    /// A helper method that gets authentication email data then send and save the email.
    /// - Parameters:
    ///   - code: Auth code number.
    ///   - email: Email address auth code email will be sent to.
    ///   - authCodeType: Authentication code type (register or login).
    ///   - emailMessageType: Type of email user wants to receive.
    ///
    /// - Throws: Throws an erorr when email did not send or save.
    /// - Returns: A `SendAuthCodeResponse` containing data like the email sent, auth code used and response from email sent using email client.
    private func sendAndSaveAuthCodeEmail(
        code: Int?, email: String, authCodeType: AuthCodeType, emailMessageType: EmailMessageType
    ) async throws -> SendAuthCodeResponse {
        let data = createSendAuthCodeEmailData(
            code: code, email: email, authCodeType: authCodeType)
        return try await sendAndSaveAuthCodeEmailFromData(
            data: data, emailMessageType: emailMessageType)
    }

    /// Helper method that sends and save email to user using `ZohoMailClient` and `SendAuthCodeEmailData` as input.
    /// - Parameters:
    ///   - data: Data required to send and save
    ///   - emailMessageType: Type of email message (`authCreateAccount` for register and `authLogin` for login)
    ///
    /// - Throws: Throws an erorr when email did not send or save.
    /// - Returns: A `SendAuthCodeResponse` containing data like the email sent, auth code used and response from email sent using email client.
    private func sendAndSaveAuthCodeEmailFromData(
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

    /// Helper method that creates correct data structur that will be used to send auth code email.
    /// - Parameters:
    ///   - code: Auth code number.
    ///   - email: Email address auth code email will be sent to.
    ///   - authCodeType: Authentication code type (register or login).
    ///
    /// - Returns: A `SendAuthCodeEmailData`, an object that contains all data necessary for sending email to user.
    private func createSendAuthCodeEmailData(code: Int?, email: String, authCodeType: AuthCodeType)
        -> SendAuthCodeEmailData

    {
        let senderType: EmailSenderType = .authentication
        let authCode = code ?? Int.random(in: 0..<100_000)

        logger.info(
            "Create data for send auth code email started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "code": .stringConvertible(authCode),
                "email": .string(email),
                "authCodeType": .string(authCodeType.rawValue),
            ]
        )

        let fromAddress = senderType.getSenderEmail()
        let payload = SendEmailPayload.fromTemplate(
            template: .authCode(code: authCode),
            fromAddress: fromAddress,
            toAddress: email,
            authType: authCodeType
        )
        let data: SendAuthCodeEmailData = .init(
            sendEmailPayload: payload, authCode: authCode, senderType: senderType)

        logger.info(
            "Create data for send auth code email success.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "code": .stringConvertible(authCode),
                "email": .string(email),
                "authCodeType": .string(authCodeType.rawValue),
            ]
        )
        return data
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
            try await uniqueEmailOrThrow(email: email, authType: authCodeType)
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
    /// - Parameters:
    ///   - email: Email to validate.
    ///   - authType: Authentication type (register or login).
    ///
    /// - Throws: An error if user exists with email.
    private func uniqueEmailOrThrow(email: String, authType: AuthCodeType) async throws {
        var isUnique: Bool
        do {
            isUnique =
                try await UserModel
                .query(on: database)
                .filter(\.$email == email)
                .count() == 0
        } catch {
            logger.error(
                "Unique email validation failed: error when making a query to database.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "email": .string(email),
                    "authType": .string(authType.rawValue),
                ]
            )
            throw Abort(.internalServerError)
        }

        if isUnique == false {
            logger.info(
                "Unique email validation failed: email is not unique (user already exist with the same email).",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "email": .string(email),
                    "authType": .string(authType.rawValue),
                ]
            )
            throw Abort(
                .custom(
                    code: 409, reasonPhrase: "User already exists with email '\(email)'."
                )
            )
        }

        logger.info(
            "Unique email validation success: email is unique (user does not already exist with the same email).",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "email": .string(email),
                "authType": .string(authType.rawValue),
            ]
        )
    }

    /// Authentication code is valid for login in or register or throw an error.
    /// - Parameter authCode: Authentication code to validate.
    /// - Throws: Throws an error if database query fails when calling `isAuthCodeLatest`, code is expired or a new code was generated.
    private func authCodeValidOrThrow(_ authCode: AuthenticationCodeModel)
        async throws
    {

        let code = authCode.value
        let codeType = authCode.codeType.rawValue
        let userEmail = authCode.email

        logger.info(
            "Authentication code validation started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "code": .stringConvertible(code),
                "codeType": .string(codeType),
                "userEmail": .string(userEmail),
            ]
        )

        let codeExpired = isAuthCodeExpired(authCode.expiresAt)
        var newestCode: Bool
        do {
            newestCode = try await isAuthCodeTheLatest(authCode)
        } catch {
            logger.error(
                "Authentication code validation failed: error checking if code is the latest.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "code": .stringConvertible(code),
                    "error": .string(error.localizedDescription),
                    "codeType": .string(codeType),
                    "userEmail": .string(userEmail),
                ]
            )
            throw Abort(.internalServerError)
        }

        if codeExpired == true || newestCode == false {
            logger.info(
                "Authentication code validation failed: code expired.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "code": .stringConvertible(code),
                    "codeType": .string(codeType),
                    "userEmail": .string(userEmail),
                ]
            )
            throw Abort(.custom(code: 401, reasonPhrase: "Authentication code expired."))
        }

        logger.info(
            "Authentication code validation success: code not expired.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "code": .stringConvertible(code),
                "codeType": .string(codeType),
                "userEmail": .string(userEmail),
            ]
        )
    }

    /// Validate authentication code, save user on register, authenticate user by generating and returning token with user data.
    /// - Parameters:
    ///   - user: User who wants to login.
    ///   - code: Authentication code sent to user email.
    ///   - codeType: Authentication type (register or login).
    ///
    /// - Throws: Throws an error when code is invalid or token did not save successfully.
    /// - Returns: A `BearerTokenWithUserDTO` containing the user's data and the generated bearer token for authentication.
    private func authenticate(
        user: UserModel, code: Int, codeType: AuthCodeType
    )
        async throws -> BearerTokenWithUserDTO
    {
        // TODO: improve error handling and logging.
        // TODO: refactor code into helper methods to reduce function length.
        let userEmail = user.email

        logger.info(
            "Authentication started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "user": .stringConvertible(user),
                "authType": .string(codeType.rawValue),
            ]
        )

        var authCode: AuthenticationCodeModel
        do {
            authCode = try await getAuthCodeOrThrow(code, email: userEmail, codeType: codeType)
        } catch {
            logger.info(
                "Authentication failed: could not get authentication code.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "user": .stringConvertible(user),
                    "authType": .string(codeType.rawValue),
                ]
            )
            throw error
        }

        do {
            try await authCodeValidOrThrow(authCode)
        } catch {
            logger.info(
                "Authentication failed: auth code validation failed.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "user": .stringConvertible(user),
                    "authType": .string(codeType.rawValue),
                ]
            )
            throw error
        }

        if codeType == .register {
            logger.info(
                "Save registered user to database started.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "user": .stringConvertible(user),
                    "authType": .string(codeType.rawValue),
                ]
            )

            do {
                try await user.save(on: database)
            } catch {
                logger.error(
                    "Save registerd user to database failed: error when making a query to database.",
                    metadata: [
                        "to": .string("\(String(describing: Self.self)).\(#function)"),
                        "error": .string(error.localizedDescription),
                        "user": .stringConvertible(user),
                        "authType": .string(codeType.rawValue),
                    ]
                )
                throw Abort(.internalServerError)
            }

            logger.info(
                "Save registered user to database success.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "user": .stringConvertible(user),
                    "authType": .string(codeType.rawValue),
                ]
            )
        }

        var userID: UUID
        do {
            userID = try user.requireID()
        } catch {
            logger.error(
                "Authentication failed: cannot get ID from user model object. This should never happen.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "user": .stringConvertible(user),
                    "authType": .string(codeType.rawValue),
                ]
            )
            throw Abort(.internalServerError)
        }

        do {
            if codeType == .register {
                try await deleteAllRegisterAuthCodes(email: userEmail)
            } else {
                try await deleteAllAuthCodes(id: userID)
            }
        } catch {
            logger.error(
                "Authentication failed: failed to delete all authentication codes for user.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "user": .stringConvertible(user),
                    "authType": .string(codeType.rawValue),
                ]
            )
            throw Abort(.internalServerError)
        }

        let token = generateBearerToken(id: userID, codeType: codeType)

        do {
            try await token.save(on: database)
            logger.info(
                "Bearer token saved success.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "token": .stringConvertible(token),
                    "user": .stringConvertible(user),
                    "authType": .string(codeType.rawValue),
                ]
            )
        } catch {
            logger.error(
                "Authentication failed: error saving bearer token to database.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "token": .stringConvertible(token),
                    "user": .stringConvertible(user),
                    "authType": .string(codeType.rawValue),
                ]
            )
            throw Abort(.internalServerError)
        }

        logger.info(
            "Authentication success.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "token": .stringConvertible(token),
                "user": .stringConvertible(user),
                "authType": .string(codeType.rawValue),
            ]
        )

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
        let authType: AuthCodeType = .register

        try await uniqueEmailOrThrow(email: userEmail, authType: authType)

        return try await authenticate(user: user, code: code, codeType: authType)
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
        var isLatest: Bool

        logger.info(
            "Validate authentication code latest started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "authCode": .stringConvertible(authCode),
            ]
        )

        do {
            isLatest =
                try await AuthenticationCodeModel
                .query(on: database)
                .filter(\.$expiresAt > authCode.expiresAt)
                .count() == 0
        } catch {
            logger.error(
                "Validate authentication code latest failed: error when making a query to database.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "authCode": .stringConvertible(authCode),
                    "error": .string(error.localizedDescription),
                ]
            )
            throw Abort(.internalServerError)
        }

        logger.info(
            "Authentication code latest: \(isLatest). User email '\(authCode.email))' '\(authCode.codeType)'"
        )
        return isLatest
    }

    /// Delete all authentication codes for a specific user.
    /// - Parameter userID: User ID.
    /// - Throws: Throws an error if code deletion on database fails.
    private func deleteAllAuthCodes(id userID: UUID)
        async throws
    {
        do {
            try await AuthenticationCodeModel
                .query(on: database)
                .filter(\.$user.$id == userID)
                .delete()
        } catch {
            logger.error(
                "All authentication code deletion failed for user.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "userID": .stringConvertible(userID),
                ]
            )
            throw Abort(.internalServerError)
        }
    }

    /// Delete all register authentication codes for a specific user.
    /// - Parameter userEmail: User email.
    /// - Throws: Throws an error if code deletion on database fails.
    private func deleteAllRegisterAuthCodes(email userEmail: String)
        async throws
    {
        do {
            try await AuthenticationCodeModel
                .query(on: database)
                .filter(\.$email == userEmail)
                .filter(\.$codeType == AuthCodeType.register)
                .delete()
        } catch {
            logger.error(
                "All register code deletion failed for user with email '\(userEmail)'. Error: '\(error)'",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "userEmail": .string(userEmail),
                ]
            )
            throw Abort(.internalServerError)
        }
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
        logger.info(
            "Get authentication code started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "code": .stringConvertible(code),
                "email": .string(email),
                "codeType": .string(codeType.rawValue),
            ]
        )

        var codeModel: AuthenticationCodeModel?

        do {
            codeModel =
                try await AuthenticationCodeModel
                .query(on: database)
                .filter(\.$value == code)
                .filter(\.$email == email)
                .filter(\.$codeType == codeType)
                .first()
        } catch {
            logger.error(
                "Get authentication code failed: error when making a query to database.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "code": .stringConvertible(code),
                    "email": .string(email),
                    "codeType": .string(codeType.rawValue),
                ]
            )
            throw Abort(.internalServerError)
        }

        guard let codeModelUnwrapped = codeModel
        else {
            logger.info(
                "Get authentication code not found.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "code": .stringConvertible(code),
                    "email": .string(email),
                    "codeType": .string(codeType.rawValue),
                ]
            )
            throw Abort(.custom(code: 404, reasonPhrase: "Authentication code not found."))
        }

        logger.info(
            "Get authentication code found.",
            metadata: [
                "to": "\(String(describing: Self.self)).\(#function)",
                "code": .stringConvertible(codeModelUnwrapped),
            ]
        )

        return codeModelUnwrapped
    }

    /// Logout user by removing all bearer tokens.
    /// - Parameters:
    ///   - userID: ID of user to logout.
    ///   - req: Request object to logout.
    ///
    /// - Throws:
    public func logout(user userID: UUID, req: Request) async throws {
        logger.info(
            "Logout started for user.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "userID": .stringConvertible(userID),
                "logoutRequest": .stringConvertible(req),
            ]
        )
        do {
            try await deleteAllBearerTokens(for: userID)
            req.auth.logout(UserModel.self)
        } catch {
            logger.error(
                "Logout failed for user.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "userID": .stringConvertible(userID),
                    "logoutRequest": .stringConvertible(req),
                    "error": .string(error.localizedDescription),
                ]
            )
            throw Abort(.internalServerError)
        }
        logger.info(
            "Logout success for user.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "userID": .stringConvertible(userID),
                "logoutRequest": .stringConvertible(req),
            ]
        )
    }

    /// Generate a `UserToken` with a random value.
    /// - Parameter userID: ID of the user the token is for.
    /// - Returns: A `UserTokenModel`, the generated bearer token.
    public func generateBearerToken(id userID: UUID, codeType: AuthCodeType) -> UserTokenModel {
        let tokenValue = "\([UInt8].random(count: 16).base64).\(codeType.rawValue)"
        let bearerToken: UserTokenModel = .init(
            value: tokenValue,
            userID: userID
        )
        logger.info(
            "Generated bearer token model `UserTokenModel` for user successfully.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "userTokenModel": .stringConvertible(bearerToken),
                "userID": .stringConvertible(userID),
            ]
        )
        return bearerToken
    }

    /// Get `UserModel` object from `BearerAuthorization`, an object found in `UserBearerAuthenticator`.
    /// - Parameter bearer: Bearer token object found from request in `UserBearerAuthenticator`middleware.
    /// - Throws: Throws an error when token is expired.
    /// - Returns: A `UserModel` - the user object, the owner of the bearer token.
    public func getUserFromBearerAuthorization(_ bearer: BearerAuthorization) async throws
        -> UserModel
    {
        var token: UserTokenModel
        do {
            token = try await getBearerToken(bearer.token)
            try token.validOrThrow()
        } catch {
            logger.info(
                "Get user from bearer authorization failed.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "authenticationType": .string("bearer"),
                ]
            )
            throw error
        }
        do {
            let user = try await token.$user.get(on: database)
            logger.info(
                "Get user from bearer authorization success.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "user": .stringConvertible(user),
                    "authenticationType": .string("bearer"),
                    "userTokenModel": .stringConvertible(token),
                ]
            )
            return user
        } catch {
            logger.error(
                "Get user from bearer authorization failed: could not get user model from token.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "authenticationType": .string("bearer"),
                    "userTokenModel": .stringConvertible(token),
                ]
            )
            throw Abort(.internalServerError)
        }
    }

    /// Get `UserModel` object from `BasicAuthorization`, an object found in `UserBasicAuthenticator`.
    /// - Parameter basic: Basic object containing username and password found from request in `UserBasicAuthenticator` middleware.
    /// - Throws: Throws an error when account with username does not exist or when password is incorrect.
    /// - Returns: A `UserModel` - the user whose username and password matches with email and password in `basic` parameter.
    public func getUserFromBasicAuthorization(_ basic: BasicAuthorization) async throws -> UserModel
    {
        // Avoid being too descriptive, use generic error messages to avoid exposing too much information.
        let errorMessageOnInvalidCredentials =
            "Incorrect username and/or password. Verify credentials and try again."

        var user: UserModel
        do {
            user = try await getUserFromUsernameOrThrow(
                basic.username,
                userNotFoundErrorMessage: errorMessageOnInvalidCredentials
            )
        } catch {
            logger.info(
                "Get user from basic authorization failed: could not get user from username.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "password": .string(basic.password),
                    "username": .string(basic.username),
                    "authenticationType": .string("basic"),
                ]
            )
            throw error
        }
        var passwordCorrect: Bool
        do {
            passwordCorrect = try Bcrypt.verify(basic.password, created: user.passwordHash)
        } catch {
            logger.error(
                "Get user from basic authorization failed: error verifying password using `Bcrypt`.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "user": .stringConvertible(user),
                    "password": .string(basic.password),
                    "username": .string(basic.username),
                    "authenticationType": .string("basic"),
                ]
            )
            throw Abort(.internalServerError)
        }

        if passwordCorrect == true {
            logger.info(
                "Get user from basic authorization success: password correct.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "user": .stringConvertible(user),
                    "password": .string(basic.password),
                    "username": .string(basic.username),
                    "authenticationType": .string("basic"),
                ]
            )
            return user
        } else {
            logger.info(
                "Get user from basic authorization failed: password incorrect.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "user": .stringConvertible(user),
                    "password": .string(basic.password),
                    "username": .string(basic.username),
                    "authenticationType": .string("basic"),
                ]
            )
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
        var user: UserModel?
        do {
            user =
                try await UserModel
                .query(on: database)
                .filter(\.$username == username)
                .first()
        } catch {
            logger.error(
                "Get user from username failed: error when making a query to database.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "error": .string(error.localizedDescription),
                    "username": .string(username),
                ]
            )
            throw Abort(.internalServerError)
        }

        guard
            let unwrappedUser = user
        else {
            logger.info(
                "Get user from username failed: user not found with username.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "username": .string(username),
                ]
            )
            throw Abort(.custom(code: 404, reasonPhrase: userNotFoundErrorMessage))
        }

        logger.info(
            "Get user from username success.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "user": .stringConvertible(unwrappedUser),
                "username": .string(username),
            ]
        )
        return unwrappedUser
    }

    /// Get `UserTokenModel` from bearer token string.
    /// - Parameter token: Token string.
    /// - Throws: Throws an error when token does not exist in database.
    /// - Returns: A `UserToken`, the bearer token object where `token` matches the object value.
    private func getBearerToken(_ token: String) async throws -> UserTokenModel {
        var userToken: UserTokenModel?
        do {
            userToken =
                try await UserTokenModel
                .query(on: database)
                .filter(\.$value == token)
                .first()
        } catch {
            logger.error(
                "Get user bearer token from token string failed: error when making a query to database.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "token": .string(token),
                    "error": .string(error.localizedDescription),
                ]
            )
            throw Abort(.internalServerError)
        }

        guard
            let userTokenUnwrapped = userToken
        else {
            logger.info(
                "Get user bearer token from token string failed: token not found with value matching token string.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "token": .string(token),
                ]
            )
            throw Abort(.custom(code: 404, reasonPhrase: "Bearer token not found."))
        }

        logger.info(
            "Get user bearer token from token string success.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "token": .string(token),
                "userTokenModel": .stringConvertible(userTokenUnwrapped),
            ]
        )
        return userTokenUnwrapped
    }

    /// Delete all bearer tokens in database for a specific user.
    /// - Parameter userID: ID of user.
    /// - Throws: Throws an error when there is a problem querying and deleting all tokens.
    private func deleteAllBearerTokens(for userID: UUID) async throws {
        do {
            try await UserTokenModel
                .query(on: database)
                .filter(\.$user.$id == userID)
                .delete()

            logger.info(
                "Delete all bearer tokens for specific user success.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "userID": .stringConvertible(userID),
                ]
            )
        } catch {
            logger.error(
                "Delete all bearer tokens for specific user failed: error when making a query to database.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "userID": .stringConvertible(userID),
                ]
            )
        }
    }
}
