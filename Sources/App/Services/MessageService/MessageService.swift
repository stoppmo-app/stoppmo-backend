// MessageService.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

enum MessageService {
    static func getEmail(_ service: EmailService) -> EmailService {
        service
    }
}
