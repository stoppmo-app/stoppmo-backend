import Fluent
import Vapor

struct AuthenticationService {
    let db: Database
    func login(user: User) async throws -> UserToken {
        let token = try self.generateToken(for: user)
        try await token.save(on: db)
        return token
    }

    func generateToken(for user: User) throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: user.requireID()
        )
    }

    func isTokenValid(token: UserToken, for user: User) async throws
        -> Bool
    {
        guard let userID = user.id else {
            throw Abort(.unauthorized)
        }

        guard
            let token =
                try await UserToken
                .query(on: db)
                .filter(\.$value, .equal, token.value)
                .filter(\.$user.$id, .equal, userID)
                .first()
        else {
            throw Abort(.unauthorized)
        }

        return token.expiresAt > Date()
    }
}
