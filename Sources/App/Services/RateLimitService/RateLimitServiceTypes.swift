protocol RateLimitResponse {
    var limitReached: Bool { get }
    var message: String? { get }
}

struct GenericRateLimitResponse: RateLimitResponse {
    var limitReached: Bool
    var message: String?
}

enum RateLimitType: String, Codable {
    case interval
    case daily
}
