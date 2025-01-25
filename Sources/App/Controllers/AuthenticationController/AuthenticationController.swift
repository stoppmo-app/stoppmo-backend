import Vapor

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.group(
            UserBasicAuthenticator(),
            UserModel.guardMiddleware()
        ) { basicProtected in
            basicProtected.post("login", use: self.login)
            basicProtected.post("login-code", use: self.sendLoginCode)
        }

        auth.group(UserBearerAuthenticator(), UserModel.guardMiddleware()) { bearerProtected in
            bearerProtected.post("logout", use: self.logout)
        }
    }

    @Sendable
    func sendLoginCode(req: Request) async throws -> HTTPStatus {
        let authService = AuthenticationService(db: req.db, client: req.client, logger: req.logger)

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
            code: sendLoginCodeResponse.authCode, userEmail: userEmail, userID: userID)

        return .ok
    }

    @Sendable
    func login(req: Request) async throws -> String {
        let authService = AuthenticationService(db: req.db, client: req.client, logger: req.logger)

        let user = try req.auth.require(UserModel.self)

        try LoginQuery.validate(query: req)
        let query = try req.query.decode(LoginQuery.self)

        return try await authService.login(user: user, authCode: query.authCode)
    }

    @Sendable
    func logout(req: Request) async throws -> HTTPStatus {
        let authService = AuthenticationService(db: req.db, client: req.client, logger: req.logger)

        guard
            let userID = try req.auth.require(UserModel.self).id
        else {
            return .badRequest
        }
        try await authService.logout(user: userID, req: req)
        return .ok
    }
}
