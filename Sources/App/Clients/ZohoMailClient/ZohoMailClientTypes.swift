// ZohoMailClientTypes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

struct FromEmailTemplateToSendEmailPayload {
}

struct SendEmailPayload: Content {
    let fromAddress: String
    let toAddress: String
    let subject: String
    let content: String

    static func fromTemplate(
        template: EmailTemplate,
        fromAddress: String,
        toAddress: String,
        authType: AuthCodeType
    ) async throws -> SendEmailPayload {
        try await template.asSendEmailPayload(
            fromAddress: fromAddress, toAddress: toAddress, authType: authType)
    }
}

struct SendEmailResponse: Content {
    let status: ZohoMailResponseStatus
    let data: SendEmailResponseData
}

struct EmailWithSendEmailResponse: Content {
    let emailMessage: EmailMessageModel
    let sentZohoMailResponse: SendEmailResponse
}

struct SendEmailInvalidTokenResponse: Content {
    let status: ZohoMailResponseStatus
    let data: SendEmailInvalidTokenResponseData
}

struct ZohoMailResponseStatus: Content {
    let code: Int
    let description: String
}

struct SendEmailResponseData: Content {
    let subject: String
    let messageId: String
    let fromAddress: String
    let mailId: String
    let toAddress: String
    let content: String
}

struct SendEmailInvalidTokenResponseData: Content {
    let errorCode: String
    let moreInfo: String?
}

struct RefreshZohoMailAccessTokenPayload: Content {
    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case clientSecret = "client_secret"
        case refreshToken = "refresh_token"
        case grantType = "grant_type"
    }

    let clientID: String
    let clientSecret: String
    let refreshToken: String
    let grantType: String
}

enum RefreshZohoMailAccessTokenGrantType: String, Codable {
    case refreshToken = "refresh_token"
}

struct RefreshZohoMailAccessTokenResponse: Content {
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case scope
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }

    let accessToken: String
    let scope: String
    let tokenType: String
    let expiresIn: Int
}

enum EmailTemplate {
    case authCode(code: Int)

    func asSendEmailPayload(
        fromAddress: String,
        toAddress: String,
        authType: AuthCodeType
    ) async throws
        -> SendEmailPayload
    {
        switch self {
        case let .authCode(code):
            let emailSubject = "StopPMO App | Two-Factor Authentication Code | \(code)"
            let content = "Welcome to StopPMO! Your \(authType) code is: <b>\(code)</b>"

            return .init(
                fromAddress: fromAddress, toAddress: toAddress, subject: emailSubject,
                content: content
            )
        }
    }
}

enum EmailSenderType: String, Codable {
    case authentication

    func getSenderEmail() -> String {
        switch self {
        case .authentication:
            "auth@stoppmo.org"
        }
    }
}
