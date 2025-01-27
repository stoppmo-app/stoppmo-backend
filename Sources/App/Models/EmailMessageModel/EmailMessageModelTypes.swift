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
            return .login
        case .authCreateAccount:
            return .register
        }
        // Comment this in once there are more message type cases added
        // default:
        //     return nil
    }
}
