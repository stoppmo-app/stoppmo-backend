import Vapor

// AuthenticationCodeModelTypes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

enum AuthCodeType: String, Codable {
    case login, register

    func toEmailMessageType(logger: Logger) throws -> EmailMessageType {
        switch self {
        case .login:
            return .authLogin
        case .register:
            return .authCreateAccount
        }
        // Comment this in once there are more message type cases added
        // default:
        //     logger.error(
        //         "Could not convert message type '\(self.rawValue)' to 'EmailMessageType' when sending auth code. This should never happen."
        //     )
        //     throw Abort(.internalServerError)
    }
}
