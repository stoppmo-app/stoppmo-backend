import Fluent
import Vapor

struct AuthenticationService {
    let db: Database
    let client: Client
    let logger: Logger

    public func sendLoginCode(email: String) async throws -> SendAuthCodeResponse {
        return try await sendAuthCode(email: email, messageType: .authLogin)
    }

    public func sendRegisterCode(email: String) async throws -> SendAuthCodeResponse {
        return try await sendAuthCode(email: email, messageType: .authCreateAccount)
    }

    public func saveAuthCode(code: Int, userEmail: String, userID: UUID)
        async throws
    {
        let authCode = AuthenticationCodeModel(value: code, email: userEmail, userID: userID)
        try await authCode.save(on: db)
    }

    private func sendAuthCode(email: String, messageType: EmailMessageType, code: Int? = nil)
        async throws
        -> SendAuthCodeResponse
    {
        let emailRateLimitService = RateLimitService.emailsService(.init(db: db, logger: logger))
        let rateLimitResponse = try await emailRateLimitService.authEmailsSent(
            email: email, messageType: messageType)

        if rateLimitResponse.limitReached == true {
            throw Abort(
                .custom(
                    code: 429,
                    reasonPhrase: rateLimitResponse.message ?? "Auth Emails Limit Reached")
            )
        }
        let emailService = MessageService.getEmail(.init(db: db, client: client, logger: logger))
        let senderType: EmailSenderType = .authentication

        // 1. Send email
        let authCode = code ?? Int.random(in: 0..<100000)

        let sendEmailResponse = try await emailService.sendEmail(
            senderType: senderType,
            payload: .fromTemplate(
                .authCode(code: authCode), from: senderType.getSenderEmail(),
                to: email),
            messageType: messageType
        )

        // 2. Save email
        let savedEmail = try await emailService.saveEmail(sendEmailResponse.emailMessage)

        // 3. Return saved email, code and response from sending email using Zoho Mail API
        return .init(
            savedEmail: savedEmail, authCode: authCode,
            sentEmailZohoMailResponse: sendEmailResponse.sentEmailZohoMailResponse)
    }

    func login(user: UserModel) async throws -> String {
        let token = try self.generateBearerToken(for: user)
        try await token.save(on: db)
        return token.value
    }

    func logout(user userID: UUID, req: Request) async throws {
        // TODO: send messages to message service here
        try await self.removeOldBearerTokens(for: userID)
        req.auth.logout(UserModel.self)

    }

    func generateBearerToken(for user: UserModel) throws -> UserTokenModel {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: user.requireID()
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
        return try await token.$user.get(on: db)
    }

    func getUserFromBasicAuthorization(_ basic: BasicAuthorization) async throws -> UserModel {
        // 1. Get user from db
        guard
            let user =
                try await UserModel
                .query(on: db)
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
                .query(on: db)
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
            .query(on: db)
            .filter(\.$user.$id, .equal, userID)
            .all()

        for token in tokens {
            try await token.delete(on: db)
        }
    }
}
