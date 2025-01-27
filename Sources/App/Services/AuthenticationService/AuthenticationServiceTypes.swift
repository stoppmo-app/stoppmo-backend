// AuthenticationServiceTypes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    typealias UserModel = App.UserModel

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
        let authService = AuthenticationService(
            database: request.db, client: request.client, logger: request.logger
        )
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
            database: request.db, client: request.client, logger: request.logger
        )
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

    enum CodingKeys: String, CodingKey {
        case authCode = "auth_code"
    }

    static func validations(_ validations: inout Validations) {
        validations.add(
            "auth_code", as: Int.self, is: .valid, required: true,
            customFailureDescription: "'auth_code' query parameter not found."
        )
    }
}

struct SendRegisterCodePayload: Content {
    let email: String
}

struct BearerTokenWithUserDTO: Content {
    let token: String
    let user: UserDTO.GetUser
}
