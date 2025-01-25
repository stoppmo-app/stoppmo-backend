import Fluent
import Vapor

struct EmailService {
    let db: Database
    let client: Client
    let logger: Logger
    private let zohoMailAPIBaseUrl = "https://mail.zoho.com/api"

    public func sendEmail(
        senderType: EmailSenderType, content: SendZohoMailEmailPayload, maxRetries: Int = 5,
        token zohoAccessToken: String? = nil
    )
        async throws -> SendZohoMailEmailResponse
    {
        // TODO: Use Redis or the database to store the latest generated token
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

        let fromAddress = content.fromAddress
        let toAddress = content.toAddress

        logger.info("Sending an email from '\(fromAddress)' to '\(toAddress)'")

        let response = try await client.post(url) { req in
            try req.content.encode(content)
            let auth = BearerAuthorization(token: token)
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

}
