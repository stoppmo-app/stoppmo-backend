import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")

        users.get(use: self.getAllUsers)
        // users.post(use: self.create)
        // users.group(":userID") { todo in
        //     todo.delete(use: self.delete)
        // }
    }

    @Sendable
    func getAllUsers(req: Request) async throws -> [TodoDTO] {
        try await User.query(on: req.db).all().map { $0.toDTO() }
    }

    // @Sendable
    // func create(req: Request) async throws -> TodoDTO {
    //     let todo = try req.content.decode(TodoDTO.self).toModel()

    //     try await todo.save(on: req.db)
    //     return todo.toDTO()
    // }

    // @Sendable
    // func delete(req: Request) async throws -> HTTPStatus {
    //     guard let todo = try await Todo.find(req.parameters.get("todoID"), on: req.db) else {
    //         throw Abort(.notFound)
    //     }

    //     try await todo.delete(on: req.db)
    //     return .noContent
    // }
}
