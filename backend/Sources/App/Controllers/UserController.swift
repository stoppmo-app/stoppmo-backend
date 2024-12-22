import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")

        users.get(use: self.getAllUsers)
        users.post(use: self.create)

        users.group(":userID") { user in
            user.get(use: self.getUserInfo)
            user.delete(use: self.deleteUser)
            user.put(use: self.updateUser)
        }
    }

    @Sendable
    func getAllUsers(req: Request) async throws -> [UserDTO] {
        try await User.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func create(req: Request) async throws -> UserDTO {
        let user = try req.content.decode(UserDTO.self).toModel()

        try await user.save(on: req.db)
        return user.toDTO()
    }

    @Sendable
    func getUserInfo(req: Request) async throws -> UserDTO {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return user.toDTO()
    }

    @Sendable
    func deleteUser(req: Request) async throws -> HTTPStatus {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await user.delete(on: req.db)
        return .noContent
    }

    @Sendable
    func updateUser(req: Request) async throws -> UserDTO {
        let updatedUser = try req.content.decode(UserDTO.self)
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }

        user.name = updatedUser.name ?? user.name
        user.surname = updatedUser.surname ?? user.surname
        user.password = updatedUser.password ?? user.password
        user.userRole = updatedUser.userRole ?? user.userRole

        try await user.update(on: req.db)
        return user.toDTO()
    }
}
