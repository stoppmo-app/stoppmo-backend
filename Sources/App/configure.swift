// configure.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // In production environment, it will use DATABASE_URL
    if let databaseURL = Environment.get("DATABASE_URL") {
        app.logger.info("Database URL: \(databaseURL)")
        try app.databases.use(.postgres(url: databaseURL), as: .psql)
    } else {
        try app.databases.use(
            DatabaseConfigurationFactory.postgres(
                configuration: .init(
                    hostname: Environment.get("DATABASE_HOST") ?? "localhost",
                    port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:))
                        ?? SQLPostgresConfiguration.ianaPortNumber,
                    username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
                    password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
                    database: Environment.get("DATABASE_NAME") ?? "vapor_database",
                    tls: .prefer(.init(configuration: .clientDefault))
                )
            ), as: .psql
        )
    }

    // use leaf templates for views
    app.views.use(.leaf)

    // add all migrations
    app.migrations.addGroup(UserMigrations())
    app.migrations.addGroup(BadgeMigrations())
    app.migrations.addGroup(UserBadgeMigrations())

    // Automatically run migrations on database
    try await app.autoMigrate()

    // register routes
    try routes(app)
}
