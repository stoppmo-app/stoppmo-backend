import Vapor

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped([User.authenticator(), User.guardMiddleware()])
        auth.post("login", use: self.login)
        auth.post("logout", use: self.logout)
    }

    @Sendable
    func login(req: Request) async throws -> UserToken {
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
        try await authService.logout(user: userID)
        return .ok
    }
}
