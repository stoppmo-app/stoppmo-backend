import Fluent
import Vapor

struct AuthenticationService {
    let db: Database

    // TODO: add some two step verification to verify the email belongs to the creator

    func login(user: User) async throws -> UserToken {
        let token = try self.generateToken(for: user)
        try await token.save(on: db)
        return token
    }

    func logout(user userID: UUID) async throws {
        // TODO: send messages to message service here
        try await self.removeOldTokens(for: userID)
    }

    func generateToken(for user: User) throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: user.requireID()
        )
    }

    static func isTokenValid(token: UserToken) -> Bool {
        token.expiresAt > Date()
    }

    func removeOldTokens(for userID: UUID) async throws {
        let tokens = try await UserToken
            .query(on: db)
            .filter(\.$user.$id, .equal, userID)
            .all()

        for token in tokens {
            try await token.delete(on: db)
        }
    }
}
