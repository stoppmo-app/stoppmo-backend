// EmailMessageModelTypes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

enum EmailMessageType: String, Codable {
    case authLogin, authCreateAccount

    func toAuthType() -> AuthCodeType? {
        switch self {
        case .authLogin:
            .login
        case .authCreateAccount:
            .register
        }
        // Comment this in once there are more message type cases added
        // default:
        //     return nil
    }
}
