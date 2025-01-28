// EmailServiceTypes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

struct FromEmailTemplateToSendZohoEmailPayloadParams {
    let fromAddress: String
    let toAddress: String
    let authType: AuthCodeType
}

struct SendZohoMailEmailPayload: Content {
    let fromAddress: String
    let toAddress: String
    let subject: String
    let content: String

    static func fromTemplate(
        template: EmailTemplate, emailParams: FromEmailTemplateToSendZohoEmailPayloadParams
    ) async throws -> SendZohoMailEmailPayload {
        try await template.asSendEmailPayload(emailParams)
    }
}

struct SendZohoMailEmailResponse: Content {
    let status: ZohoMailResponseStatus
    let data: SendZohoMailEmailResponseData
}

struct EmailMessageModelWithSendZohoMailEmailResponse: Content {
    let emailMessage: EmailMessageModel
    let sentEmailZohoMailResponse: SendZohoMailEmailResponse
}

struct SendZohoMailEmailInvalidTokenResponse: Content {
    let status: ZohoMailResponseStatus
    let data: SendZohoMailEmailInvalidTokenResponseData
}

struct ZohoMailResponseStatus: Content {
    let code: Int
    let description: String
}

struct SendZohoMailEmailResponseData: Content {
    let subject: String
    let messageId: String
    let fromAddress: String
    let mailId: String
    let toAddress: String
    let content: String
}

struct SendZohoMailEmailInvalidTokenResponseData: Content {
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

struct SendEmailLeafTemplateContext: Encodable {
    let subject: String
    let authType: String
    let codeArray: [Int]
}

enum EmailTemplate {
    case authCode(code: Int)

    func asSendEmailPayload(_ params: FromEmailTemplateToSendZohoEmailPayloadParams) async throws
        -> SendZohoMailEmailPayload
    {
        let fromAddress = params.fromAddress
        let toAddress = params.toAddress
        let authType = params.authType.rawValue

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
