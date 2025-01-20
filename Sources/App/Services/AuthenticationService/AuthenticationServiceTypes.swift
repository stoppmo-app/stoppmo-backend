import Vapor

struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    typealias UserModel = App.UserModel

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
        let authService = AuthenticationService(db: request.db)
        let user = try await authService.getUserFromBearerAuthorization(bearer)
        request.auth.login(user)
    }
}

struct UserBasicAuthenticator: AsyncBasicAuthenticator {
    typealias UserModel = App.UserModel

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        let authService = AuthenticationService(db: request.db)
        let user = try await authService.getUserFromBasicAuthorization(basic)
        request.auth.login(user)
    }
}
