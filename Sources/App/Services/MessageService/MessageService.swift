import Fluent
import Vapor

struct MessageService {
    let db: Database
    let client: Client
    let logger: Logger

    func sendEmail(
        to email: String, message: String, senderAccountID: UUID, content: SendEmailPayload
    ) async throws -> SendEmailResponse {
        let emailService = EmailService(db: db, client: client, logger: logger)
        return try await emailService.sendEmail(
            to: email, message: message, senderAccountID: senderAccountID, content: content)
    }
}
