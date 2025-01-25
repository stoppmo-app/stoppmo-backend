import Fluent
import Vapor

struct MessageService {
    let db: Database
    let client: Client
    let logger: Logger

    func sendEmail(
        senderType: EmailSenderType, content: SendZohoMailEmailPayload, maxRetries: Int = 5,
        token zohoAccessToken: UUID? = nil
    ) async throws -> SendZohoMailEmailResponse {
        let emailService = EmailService(db: db, client: client, logger: logger)
        return try await emailService.sendEmail(senderType: senderType, content: content)
    }
}
