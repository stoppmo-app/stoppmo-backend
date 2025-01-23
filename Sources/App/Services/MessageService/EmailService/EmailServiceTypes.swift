import Fluent
import Vapor

struct SendEmailPayload: Content {
    let fromAddress: String
    let toAddress: String
    let subject: String
    let content: String

    static func fromTemplate(_ template: EmailTemplate, to toAddress: String) -> SendEmailPayload {
        return template.asSendEmailPayload(toAddress: toAddress)
    }
}

struct SendEmailResponse: Content {
    let status: SendEmailResponseStatus
    let data: SendEmailResponseData
}

struct SendEmailResponseStatus: Content {
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

enum EmailTemplate {
    case authCode(code: Int)

    func asSendEmailPayload(toAddress: String) -> SendEmailPayload {
        switch self {
        case let .authCode(code):
            // TODO: Use a leaf template as the content.
            return .init(
                fromAddress: "auth@stoppmo.org", toAddress: toAddress,
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
