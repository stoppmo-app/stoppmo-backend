// EmailServiceTypes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

struct SendZohoMailEmailPayload: Content {
    let fromAddress: String
    let toAddress: String
    let subject: String
    let content: String

    static func fromTemplate(
        _ template: EmailTemplate, from fromAddress: String, to toAddress: String
    ) -> SendZohoMailEmailPayload {
        template.asSendEmailPayload(fromAddress: fromAddress, toAddress: toAddress)
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

enum EmailTemplate {
    case authCode(code: Int)

    func asSendEmailPayload(fromAddress: String, toAddress: String) -> SendZohoMailEmailPayload {
        switch self {
        case let .authCode(code):
            // TODO: Use a leaf template as the content.
            .init(
                fromAddress: fromAddress, toAddress: toAddress,
                subject: "StopPMO App | Two-Factor Authentication Code | \(code)",
                content: "Your authentication code is \(code)."
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
