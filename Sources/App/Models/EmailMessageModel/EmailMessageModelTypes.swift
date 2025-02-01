// EmailMessageModelTypes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

enum EmailMessageType: String, Codable {
    case authLogin, authCreateAccount

    func toAuthType() throws -> AuthCodeType? {
        switch self {
        case .authLogin:
            .login
        case .authCreateAccount:
            .register
        }
        // Comment this in once there are more message type cases added
        // default:
        //     logger.error(
        //         "Could not convert message type \(self.rawValue) to 'AuthCodeType' when sending auth code. This should never happen."
        //     )
        //     throw Abort(.internalServerError)
    }
}
