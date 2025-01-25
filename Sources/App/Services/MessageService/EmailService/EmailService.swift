import Fluent
import Vapor

struct EmailService {
    let db: Database
    let client: Client
    let logger: Logger
    private let zohoMailAPIBaseUrl = "https://mail.zoho.com/api"

    public func sendEmail(
        senderType: EmailSenderType, content: SendZohoMailEmailPayload, maxRetries: Int = 5,
        token zohoAccessToken: UUID? = nil
    )
        async throws -> SendZohoMailEmailResponse
    {
        // TODO: Use Redis or the database to store the latest generated token
        // Get that token. If it does not work, generate a new token and delete the previous ones

        var token: UUID
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

        let url = URI(path: "\(zohoMailAPIBaseUrl)/accounts/\(senderEmailID)/messages")
        let response = try await client.post(url) { req in
            try req.content.encode(content)
            let auth = BearerAuthorization(token: token.uuidString)
            req.headers.bearerAuthorization = auth
        }

        do {
            let responseBodyJSON = try response.content.decode(SendZohoMailEmailResponse.self)
            return responseBodyJSON
        } catch {
            // Checks if the error was because of an invalid token
            let _ = try response.content.decode(
                SendZohoMailEmailInvalidTokenResponse.self)
            if maxRetries == 0 {
                logger.error(
                    "Invalid ZOHO access token, unable to refresh token successfully. Reached max retries for sending emails from sender type '\(senderType.rawValue)' to email '\(content.toAddress)'."
                )
                throw Abort(.custom(code: 500, reasonPhrase: "Max email send retries reached."))
            }
            return try await sendEmail(
                senderType: senderType, content: content, maxRetries: maxRetries - 1,
                token: refreshAndGetNewZohoAccessToken())
        }
    }

    // TODO: implement function logic
    private func refreshAndGetNewZohoAccessToken() async throws -> UUID {
        let url = URI(path: "https://accounts.zoho.com/oauth/v2/token")

        guard
            let clientIDString = Environment.get("ZOHO_CLIENT_ID"),
            let clientID = UUID(uuidString: clientIDString)
        else {
            logger.error("'ZOHO_CLIENT_ID' environment variable not found.")
            throw Abort(.internalServerError)
        }
        guard
            let clientTokenString = Environment.get("ZOHO_CLIENT_TOKEN"),
            let clientToken = UUID(uuidString: clientTokenString)
        else {
            logger.error("'ZOHO_CLIENT_TOKEN' environment variable not found.")
            throw Abort(.internalServerError)
        }
        guard
            let refreshTokenString = Environment.get("ZOHO_REFRESH_TOKEN"),
            let refreshToken = UUID(uuidString: refreshTokenString)
        else {
            logger.error("'ZOHO_REFRESH_TOKEN' environment variable not found.")
            throw Abort(.internalServerError)
        }

        let content = RefreshZohoMailAccessTokenPayload(
            client_id: clientID, client_token: clientToken, refresh_token: refreshToken,
            grant_type: .refreshToken)

        let response = try await client.post(url) { req in
            try req.content.encode(content)
        }

        let responseBodyJSON = try response.content.decode(RefreshZohoMailAccessTokenResponse.self)
        return responseBodyJSON.access_token
    }
}
