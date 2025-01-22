import Vapor

struct SendEmailPayload: Content {
    let fromAddress: String
    let toAddress: String
    let string: String
    let content: String
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
