import Vapor

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.group([
            UserBasicAuthenticator(),
            User.guardMiddleware(),
        ]) { basicProtected in
            basicProtected.post("login", use: self.login)
        }

        routes.group([
            UserBearerAuthenticator(),
            User.guardMiddleware(),
        ]) { bearerProtected in
            bearerProtected.post("logout", use: self.logout)
        }
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
