protocol RateLimitResponse {
    var limitReached: Bool { get }
    var message: String? { get }
}

struct GenericRateLimitResponse: RateLimitResponse {
    var limitReached: Bool
    var message: String?
}
