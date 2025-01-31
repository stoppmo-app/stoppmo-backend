// routes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get("hello") { req async -> String in
        return "Hello Review App Test!"
    }

    // register all controllers
    try app.register(collection: UserController())
    try app.register(collection: BadgeController())
    try app.register(collection: UserBadgeController())
    try app.register(collection: AuthenticationController())
}
