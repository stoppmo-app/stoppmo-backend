import Fluent
import Vapor

struct AuthenticationService {
    let db: Database

    // TODO: add some two step verification to verify the email belongs to the creator

    func login(user: User) async throws -> String {
        let token = try self.generateBearerToken(for: user)
        try await token.save(on: db)
        return token.value
    }

    func logout(user userID: UUID, req: Request) async throws {
        // TODO: send messages to message service here
        try await self.removeOldBearerTokens(for: userID)
        req.auth.logout(User.self)

    }

    func generateBearerToken(for user: User) throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: user.requireID()
        )
    }

    func getUserFromBearerAuthorization(_ bearer: BearerAuthorization) async throws -> User {
        // 1. Get token from db
        let token = try await getBearerToken(bearer.token)

        // 2. Validate token
        if token.isTokenValid() == false {
            throw Abort(.custom(code: 401, reasonPhrase: "Token Expired"))
        }

        // 3. Return user
        return try await token.$user.get(on: db)
    }

    func getUserFromBasicAuthorization(_ basic: BasicAuthorization) async throws -> User {
        // 1. Get user from db
        guard
            let user =
                try await User
                .query(on: db)
                .filter(\.$username, .equal, basic.username)
                .first()
        else {
            throw Abort(.notFound)
        }

        // 2. Verify password
        let passwordCorrect = try Bcrypt.verify(basic.password, created: user.passwordHash)

        // 3. Return user
        if passwordCorrect == true {
            return user
        } else {
            throw Abort(.unauthorized)
        }
    }

    func getBearerToken(_ token: String) async throws -> UserToken {
        guard
            let userToken =
                try await UserToken
                .query(on: db)
                .filter(\.$value, .equal, token)
                .first()
        else {
            throw Abort(.custom(code: 401, reasonPhrase: "Token Not Found"))
        }
        return userToken
    }

    func removeOldBearerTokens(for userID: UUID) async throws {
        let tokens =
            try await UserToken
            .query(on: db)
            .filter(\.$user.$id, .equal, userID)
            .all()

        for token in tokens {
            try await token.delete(on: db)
        }
    }
}
