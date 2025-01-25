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

        // 1. Send email
        let userEmail = try req.auth.require(UserModel.self).email
        // let sendLoginCodeResponse = try await authService.sendLoginCode(email: userEmail)
        let _ = try await authService.sendLoginCode(email: userEmail) // Remove this line

        // 2. Save code
        // TODO: create this method
        // authService.saveLoginCode()
        return .ok
    }

    @Sendable
    func login(req: Request) async throws -> String {
        let authService = AuthenticationService(db: req.db, client: req.client, logger: req.logger)

        let user = try req.auth.require(UserModel.self)
        return try await authService.login(user: user)
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
