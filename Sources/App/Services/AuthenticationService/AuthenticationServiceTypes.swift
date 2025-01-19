import Vapor

struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
        let authService = AuthenticationService(db: request.db)
        print("Getting user from bearer token")
        print("Bearer Token: \(bearer.token)")
        let user = try await authService.getUserFromBearerAuthorization(bearer)
        request.auth.login(user)
    }
}

struct UserBasicAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        let authService = AuthenticationService(db: request.db)
        let user = try await authService.getUserFromBasicAuthorization(basic)
        request.auth.login(user)
    }
}
