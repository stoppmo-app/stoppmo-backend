import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req async -> String in
        "Hello there world!"
    }

    try app.register(collection: UserController())
    try app.register(collection: BadgeController())
    try app.register(collection: UserBadgeController())
}
