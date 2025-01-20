import Fluent
import Vapor

struct RateLimitService {
    let db: Database

    func authEmailsSent(email: String) async throws -> Bool {
        // TODO: implement method logic
        throw Abort(.notImplemented)
    }
}
