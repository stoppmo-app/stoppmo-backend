import Vapor

struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    typealias UserModel = App.UserModel

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
        let authService = AuthenticationService(
            db: request.db, client: request.client, logger: request.logger)
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
        let authService = AuthenticationService(
            db: request.db, client: request.client, logger: request.logger)
        let user = try await authService.getUserFromBasicAuthorization(basic)
        request.auth.login(user)
    }
}

struct SendAuthCodeResponse: Content {
    let savedEmail: EmailMessageModel
    let authCode: Int
    let sentEmailZohoMailResponse: SendZohoMailEmailResponse
}

struct LoginAndRegisterQuery: Content, Validatable {
    let authCode: Int

    static func validations(_ validations: inout Validations) {
        validations.add(
            "authCode", as: Int.self, is: .valid, required: true,
            customFailureDescription: "'authCode' query parameter not found.")
    }
}

struct SendRegisterCodePayload: Content {
    let email: String
}

struct BearerTokenWithUserDTO: Content {
    let token: String
    let user: UserDTO.GetUser
}
