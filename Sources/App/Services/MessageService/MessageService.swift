import Fluent
import Vapor

struct MessageService {
    let db: Database
    let client: Client
    let logger: Logger

    func sendEmail(
        senderType: EmailSenderType, content: SendEmailPayload
    ) async throws -> SendEmailResponse {
        let emailService = EmailService(db: db, client: client, logger: logger)
        return try await emailService.sendEmail(senderType: senderType, content: content)
    }
}
