import Fluent
import Vapor

struct AuthenticationService {
    let db: Database

    // TODO: add some two step verification to verify the email belongs to the creator

    func login(user: User) async throws -> String {
        let token = try self.generateToken(for: user)
        try await token.save(on: db)
        return token.value
    }

    func logout(user userID: UUID, req: Request) async throws {
        // TODO: send messages to message service here
        try await self.removeOldTokens(for: userID)
        req.auth.logout(User.self)
    }

    func generateToken(for user: User) throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: user.requireID()
        )
    }

    func getUserFromToken(_ token: String) async throws -> User {
        // 1. Get token from db
        let token = try await getToken(token)
        // 2. validate token
        if token.isTokenValid() == false {
            throw Abort(.custom(code: 401, reasonPhrase: "Token Expired"))
        }
        // 3. return user
        return token.user
    }

    func getToken(_ token: String) async throws -> UserToken {
        guard let userToken = try await UserToken
            .query(on: db)
            .filter(\.$value, .equal, token)
            .first()
        else {
            throw Abort(.custom(code: 401, reasonPhrase: "Token Not Found"))
        }
        return userToken
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
