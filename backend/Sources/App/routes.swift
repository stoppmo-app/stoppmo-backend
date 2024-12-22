import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello 1234 Vapor!"])
    }

    app.get("hello") { req async -> String in
        "Hello there world!"
    }

    try app.register(collection: TodoController())
}
