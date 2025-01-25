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
        return template.asSendEmailPayload(fromAddress: fromAddress, toAddress: toAddress)
    }
}

struct SendZohoMailEmailResponse: Content {
    let status: ZohoMailResponseStatus
    let data: SendZohoMailEmailResponseData
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
    let client_id: UUID
    let client_token: UUID
    let refresh_token: UUID
    let grant_type: RefreshZohoMailAccessTokenGrantType
}

enum RefreshZohoMailAccessTokenGrantType: String, Codable {
    case refreshToken = "refresh_token"
}

struct RefreshZohoMailAccessTokenResponse: Content {
    let access_token: UUID
    let scope: String
    let token_type: String
    let expires_in: Int
}

enum EmailTemplate {
    case authCode(code: Int)

    func asSendEmailPayload(fromAddress: String, toAddress: String) -> SendZohoMailEmailPayload {
        switch self {
        case let .authCode(code):
            // TODO: Use a leaf template as the content.
            return .init(
                fromAddress: fromAddress, toAddress: toAddress,
                subject: "StopPMO App | Two-Factor Authentication Code | \(code)",
                content: "Your authentication code is \(code).")
        }
    }
}

enum EmailSenderType: String, Codable {
    case authentication

    func getSenderEmail() -> String {
        switch self {
        case .authentication:
            return "auth@stoppmo.org"
        }
    }
}
