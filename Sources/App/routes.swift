// routes.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Test Review App!"])
    }

    app.get("hello") { _ async -> String in
        "Hello there world!"
    }

    // register all controllers
    try app.register(collection: UserController())
    try app.register(collection: BadgeController())
    try app.register(collection: UserBadgeController())
    try app.register(collection: AuthenticationController())
}
