import Fluent
import Vapor

struct EmailService {
    let db: Database
    let client: Client
    let logger: Logger
    private let zohoMailAPIBaseUrl = "https://mail.zoho.com/api"

    public func sendEmail(
        senderType: EmailSenderType, payload: SendZohoMailEmailPayload,
        messageType: EmailMessageType, maxRetries: Int = 5,
        token zohoAccessToken: String? = nil
    ) async throws -> EmailMessageModelWithSendZohoMailEmailResponse {
        let zohoResponse = try await sendZohoEmail(
            senderType: senderType, payload: payload, maxRetries: maxRetries, token: zohoAccessToken
        )
        let emailMessageModel = try await getEmailMessageModelFromEmailSent(
            payload: payload, messageType: messageType)

        return .init(emailMessage: emailMessageModel, sentEmailZohoMailResponse: zohoResponse)
    }

    public func saveEmail(_ emailMessageModel: EmailMessageModel) async throws -> EmailMessageModel
    {
        do {
            try await emailMessageModel.save(on: db)
        } catch {
            logger.error(
                "Failed to save `EmailMessageModel` to database - \(emailMessageModel). Error: \(String(reflecting: error))"
            )
            throw Abort(.internalServerError)
        }
        return emailMessageModel
    }

    private func getEmailMessageModelFromEmailSent(
        payload: SendZohoMailEmailPayload, messageType: EmailMessageType
    ) async throws -> EmailMessageModel {
        let sentToEmail = payload.toAddress
        let sentFromEmail = payload.fromAddress
        let sentTo = try await getUserIDFromEmail(sentToEmail)

        return .init(
            messageType: messageType, subject: payload.subject, content: payload.content,
            sentAt: Date(), sentTo: sentTo, sentToEmail: sentToEmail, sentFromEmail: sentFromEmail)
    }

    private func getUserIDFromEmail(_ email: String) async throws -> UUID? {
        let user =
            try await UserModel
            .query(on: db)
            .filter(\.$email, .equal, email)
            .field(\.$id)
            .first()
        let id = try? user?.requireID()
        return id
    }

    private func sendZohoEmail(
        senderType: EmailSenderType, payload: SendZohoMailEmailPayload, maxRetries: Int = 5,
        token zohoAccessToken: String? = nil
    )
        async throws -> SendZohoMailEmailResponse
    {
        // TODO: Use Redis or the database to store the latest generated token
        // Reason? If a lot of emails get sent in a short period of time, Zoho Mail will rate limit
        // the ability to generate a new access token.
        // Get that token. If it does not work, generate a new token and delete the previous ones

        var token: String
        if let zohoAccessToken {
            token = zohoAccessToken
        } else {
            token = try await refreshAndGetNewZohoAccessToken()
        }

        guard
            let senderEmailID = Environment.get("ZOHO_MAIL_AUTH_SENDER_ID")
        else {
            logger.error("Did not find 'ZOHO_MAIL_AUTH_SENDER_ID' environment variable.")
            throw Abort(.internalServerError)
        }

        let url = URI(string: "\(zohoMailAPIBaseUrl)/accounts/\(senderEmailID)/messages")

        let fromAddress = payload.fromAddress
        let toAddress = payload.toAddress

        logger.info("Sending an email from '\(fromAddress)' to '\(toAddress)'")

        let response = try await client.post(url) { req in
            try req.content.encode(payload)
            let auth = BearerAuthorization(token: token)
            req.headers.bearerAuthorization = auth
        }

        do {
            let responseBodyJSON = try response.content.decode(SendZohoMailEmailResponse.self)

            try handleZohoMailEmailSentSuccess(
                responseBodyJSON, fromAddress: fromAddress, toAddress: toAddress)

            return responseBodyJSON
        } catch {
            return try await handleZohoMailEmailSentInvalidToken(
                response: response, senderType: senderType, payload: payload, maxRetries: maxRetries
            )
        }
    }

    private func handleZohoMailEmailSentInvalidToken(
        response: ClientResponse, senderType: EmailSenderType, payload: SendZohoMailEmailPayload,
        maxRetries: Int
    ) async throws -> SendZohoMailEmailResponse {
        let _ = try response.content.decode(
            SendZohoMailEmailInvalidTokenResponse.self)
        if maxRetries == 0 {
            logger.error(
                "Invalid ZOHO access token, unable to refresh token successfully. Reached max retries for sending emails from sender type '\(senderType.rawValue)' to email '\(payload.toAddress)'."
            )
            throw Abort(.custom(code: 500, reasonPhrase: "Max email send retries reached."))
        }
        return try await sendZohoEmail(
            senderType: senderType, payload: payload, maxRetries: maxRetries - 1,
            token: refreshAndGetNewZohoAccessToken())
    }

    private func handleZohoMailEmailSentSuccess(
        _ responseBodyJSON: SendZohoMailEmailResponse, fromAddress: String, toAddress: String
    ) throws {
        let success =
            responseBodyJSON.status.code == 200 && responseBodyJSON.status.description == "success"
        if success == false {
            logger.error(
                "Email did not send successfully from '\(fromAddress)' to '\(toAddress)' using Zoho API. Response: \(responseBodyJSON)"
            )
            throw Abort(.internalServerError)
        }
    }

    private func refreshAndGetNewZohoAccessToken() async throws -> String {
        let url = URI(string: "https://accounts.zoho.com/oauth/v2/token")

        guard
            let clientID = Environment.get("ZOHO_CLIENT_ID")
        else {
            logger.error("'ZOHO_CLIENT_ID' environment variable not found.")
            throw Abort(.internalServerError)
        }
        guard
            let clientSecret = Environment.get("ZOHO_CLIENT_SECRET")
        else {
            logger.error("'ZOHO_CLIENT_SECRET' environment variable not found.")
            throw Abort(.internalServerError)
        }
        guard
            let refreshToken = Environment.get("ZOHO_REFRESH_TOKEN")
        else {
            logger.error("'ZOHO_REFRESH_TOKEN' environment variable not found.")
            throw Abort(.internalServerError)
        }
        let content = RefreshZohoMailAccessTokenPayload(
            client_id: clientID, client_secret: clientSecret, refresh_token: refreshToken,
            // grant_type: .refreshToken)
            grant_type: "refresh_token")

        let response = try await client.post(url) { req in
            try req.content.encode(content, as: .formData)
        }

        let responseBodyJSON = try response.content.decode(RefreshZohoMailAccessTokenResponse.self)
        let accessToken = responseBodyJSON.access_token
        return accessToken
    }

    public func saveEmail() async throws {
        throw Abort(.notImplemented)
    }
}
