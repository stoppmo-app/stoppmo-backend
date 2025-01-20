import Vapor

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.group(
            UserBasicAuthenticator(),
            User.guardMiddleware()
        ) { basicProtected in
            basicProtected.post("login", use: self.login)
            basicProtected.post("login-code", use: self.sendLoginCode)
        }

        auth.group(UserBearerAuthenticator(), User.guardMiddleware()) { bearerProtected in
            bearerProtected.post("logout", use: self.logout)
        }
    }

    @Sendable
    func sendLoginCode(req: Request) async throws -> HTTPStatus {
        let authService = AuthenticationService(db: req.db)

        let userEmail = try req.auth.require(User.self).email
        try await authService.sendLoginCode(email: userEmail)
        return .ok
    }

    @Sendable
    func login(req: Request) async throws -> String {
        let authService = AuthenticationService(db: req.db)

        let user = try req.auth.require(User.self)
        return try await authService.login(user: user)
    }

    @Sendable
    func logout(req: Request) async throws -> HTTPStatus {
        let authService = AuthenticationService(db: req.db)

        guard
            let userID = try req.auth.require(User.self).id
        else {
            return .badRequest
        }
        try await authService.logout(user: userID, req: req)
        return .ok
    }
}
