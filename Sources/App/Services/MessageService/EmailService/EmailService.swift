// EmailService.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

struct EmailService {
    let database: Database
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
            payload: payload, messageType: messageType
        )

        return .init(emailMessage: emailMessageModel, sentEmailZohoMailResponse: zohoResponse)
    }

    public func saveEmail(_ emailMessageModel: EmailMessageModel) async throws -> EmailMessageModel {
        do {
            try await emailMessageModel.save(on: database)
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
            sentAt: Date(), sentTo: sentTo, sentToEmail: sentToEmail, sentFromEmail: sentFromEmail
        )
    }

    private func getUserIDFromEmail(_ email: String) async throws -> UUID? {
        let user =
            try await UserModel
                .query(on: database)
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
        var refreshedToken = false

        let token: String = try await {
            if let zohoAccessToken {
                return zohoAccessToken
            } else {
                guard
                    let tokenFromDatabase = try await getZohoAccessToken()
                else {
                    refreshedToken = true
                    return try await refreshAndSaveZohoAccessToken()
                }
                return tokenFromDatabase
            }
        }()

        guard
            let senderEmailID = Environment.get("ZOHO_MAIL_AUTH_SENDER_ID")
        else {
            logger.error("Did not find 'ZOHO_MAIL_AUTH_SENDER_ID' environment variable.")
            throw Abort(.internalServerError)
        }

        let url = URI(string: "\(zohoMailAPIBaseUrl)/accounts/\(senderEmailID)/messages")

        let fromAddress = payload.fromAddress
        let toAddress = payload.toAddress

        let response = try await client.post(url) { req in
            try req.content.encode(payload)
            let auth = BearerAuthorization(token: token)
            req.headers.bearerAuthorization = auth
        }

        do {
            let responseBodyJSON = try response.content.decode(SendZohoMailEmailResponse.self)

            try handleZohoMailEmailSentSuccess(
                responseBodyJSON, fromAddress: fromAddress, toAddress: toAddress
            )

            return responseBodyJSON
        } catch {
            if refreshedToken == true {
                logger.error(
                    "New Zoho access token was generated and used to send and email using Zoho Mail API (error was not caused by invalid access token). Error: \(String(reflecting: error))"
                )
                throw Abort(.internalServerError)
            }
            return try await handleZohoMailEmailSentInvalidToken(
                response: response, senderType: senderType, payload: payload, maxRetries: maxRetries
            )
        }
    }

    private func handleZohoMailEmailSentInvalidToken(
        response: ClientResponse, senderType: EmailSenderType, payload: SendZohoMailEmailPayload,
        maxRetries: Int
    ) async throws -> SendZohoMailEmailResponse {
        _ = try response.content.decode(
            SendZohoMailEmailInvalidTokenResponse.self
        )
        if maxRetries == 0 {
            logger.error(
                "Invalid Zoho access token, unable to refresh token successfully. Reached max retries for sending emails from sender type '\(senderType.rawValue)' to email '\(payload.toAddress)'."
            )
            throw Abort(.custom(code: 500, reasonPhrase: "Max email send retries reached."))
        }
        return try await sendZohoEmail(
            senderType: senderType, payload: payload, maxRetries: maxRetries - 1,
            token: refreshAndSaveZohoAccessToken()
        )
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

    private func getZohoAccessToken() async throws -> String? {
        guard
            let pair =
            try await KeyValuePairModel
                .query(on: database)
                .filter(\.$pairType == .zohoAccessToken)
                .sort(\.$createdAt, .descending) // get latest
                .field(\.$value)
                .first()
        else {
            return nil
        }
        return pair.value
    }

    private func saveZohoAccessToken(_ token: String) async throws {
        let pair = KeyValuePairModel(
            pairType: .zohoAccessToken, key: "zoho_access_token", value: token
        )
        do {
            try await pair.save(on: database)
        } catch {
            logger.error(
                "Failed to save Zoho access token to key value pair table. Error: \(String(reflecting: error))"
            )
        }
    }

    private func refreshAndSaveZohoAccessToken() async throws -> String {
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
            clientID: clientID, clientSecret: clientSecret, refreshToken: refreshToken,
            grantType: "refresh_token"
        )

        let response = try await client.post(url) { req in
            try req.content.encode(content, as: .formData)
        }

        let responseBodyJSON = try response.content.decode(RefreshZohoMailAccessTokenResponse.self)
        let accessToken = responseBodyJSON.accessToken

        try await saveZohoAccessToken(accessToken)

        return accessToken
    }
}
