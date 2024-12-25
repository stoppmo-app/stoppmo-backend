import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")

        users.get(use: self.getAllUsers)
        users.post(use: self.createUser)

        users.group(":userID") { user in
            user.get(use: self.getUserInfo)
            user.delete(use: self.deleteUser)
            user.put(use: self.updateUser)
        }
    }

    @Sendable
    func getAllUsers(req: Request) async throws -> [UserDTO.GetUser] {
        try await User.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func createUser(req: Request) async throws -> UserDTO.GetUser {
        let user = User.fromDTO(try req.content.decode(UserDTO.CreateUser.self))

        try await user.save(on: req.db)
        return user.toDTO()
    }

    @Sendable
    func getUserInfo(req: Request) async throws -> UserDTO.GetUser {
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
    func updateUser(req: Request) async throws -> UserDTO.GetUser {
        let updatedUser = try req.content.decode(UserDTO.UpdateUser.self)
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }

        user.firstName = updatedUser.firstName ?? user.firstName
        user.lastName = updatedUser.lastName ?? user.lastName
        user.username = updatedUser.username ?? user.lastName
        user.username = updatedUser.username ?? user.lastName
        user.profilePictureURL = updatedUser.profilePictureURL ?? user.profilePictureURL
        user.bio = updatedUser.bio ?? user.bio
        user.dateOfBirth = updatedUser.dateOfBirth ?? user.dateOfBirth
        user.phoneNumber = updatedUser.phoneNumber ?? user.phoneNumber

        try await user.update(on: req.db)
        return user.toDTO()
    }
}
