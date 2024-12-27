import NIOSSL
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
        app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database",
            tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)
    }

    app.views.use(.leaf)

    // random changes here
    app.migrations.addGroup(UserMigrations())
    app.migrations.addGroup(BadgeMigrations())
    app.migrations.addGroup(UserBadgeMigrations())

    try await app.autoMigrate()

    // register routes
    try routes(app)
}