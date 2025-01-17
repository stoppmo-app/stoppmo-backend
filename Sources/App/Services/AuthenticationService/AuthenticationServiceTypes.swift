import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
        let authService = AuthenticationService(db: request.db)
        let user = try await authService.getUserFromToken(bearer.token)
        request.auth.login(user)
    }
}
