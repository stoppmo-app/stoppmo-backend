import Fluent
import Vapor

struct EmailService {
    let db: Database
    let client: Client
    let logger: Logger

    func sendEmail(
        senderType: EmailSenderType, content: SendEmailPayload
    )
        async throws -> SendEmailResponse
    {
        guard
            let zohoAccessToken = Environment.get("ZOHO_ACCESS_TOKEN")
        else {
            logger.error("ZOHO_ACCESS_TOKEN not found in environment.")
            throw Abort(.badRequest)
        }

        let senderEmail = senderType.getSenderEmail()
        let url = URI(path: "https://mail.zoho.com/api/accounts/\(senderEmail)/messages")
        let response = try await client.post(url) { req in
            try req.content.encode(content)
            let auth = BearerAuthorization(token: zohoAccessToken)
            req.headers.bearerAuthorization = auth
        }
        let responseBodyJSON = try response.content.decode(SendEmailResponse.self)
        return responseBodyJSON
    }
}
