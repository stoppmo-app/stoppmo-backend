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

    // Leaf Templates
    app.views.use(.leaf)

    // Migrations
    app.migrations.add(CreateUserModel())
    app.migrations.add(UserModelWithPassword1())
    app.migrations.add(UserModelWithDeletedAt1())
    app.migrations.add(UserModelWithUniqueFields1())
    app.migrations.add(CreateUserTokenModel())
    app.migrations.add(UserTokenModelWithTimestamps1())
    app.migrations.add(UserTokenModelWithExpiresAtField1())
    app.migrations.add(UserTokenModelWithExpiresAtAsTimestampZ())
    app.migrations.add(CreateBadgeModel())
    app.migrations.add(BadgeModelWithDeletedAt1())
    app.migrations.add(BadgeModelWithUniqueUnlockAfterDaysField1())
    app.migrations.add(SeedBadgesModel())
    app.migrations.add(CreateUserBadgeModel())
    app.migrations.add(UserBadgeModelWithParentIDReferences1())
    app.migrations.add(UserBadgeModelWithDeletedAt1())
    app.migrations.add(CreateEmailMessageModel())
    app.migrations.add(EmailMessageModelWithSentToAndSentFromEmail())
    app.migrations.add(EmailMessageModelWithEmailMessageTypeEnum())
    app.migrations.add(EmailMessageModelWithSubjectAndContent())
    app.migrations.add(EmailMessageModelWithTimestampzSentAt())
    app.migrations.add(CreateAuthenticationCodeModel())
    app.migrations.add(AuthenticationCodeModelTimestampZExpiresAt())
    app.migrations.add(AuthenticationCodeModelWithEmailMessageIDAndAuthCodeTypeFields())
    app.migrations.add(CreateKeyValuePairModel())

    try await app.autoMigrate()

    // register routes
    try routes(app)
}
