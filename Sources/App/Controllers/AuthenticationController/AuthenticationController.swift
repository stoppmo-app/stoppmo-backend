import Vapor

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped([User.authenticator()])
        // auth.get(use: getAllUsers)
    }

    @Sendable
    func login(req: Request) async throws -> UserToken {
        let authService = AuthenticationService(db: req.db)

        let user = try req.auth.require(User.self)
        return try await authService.login(user: user)
    }
}
