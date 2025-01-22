import Vapor

// TODO: Test out `EmailRateLimitService().emailsSent()` method
// TODO: Write tests for all rate limit services code

struct RateLimitService {
    static func emails(_ service: EmailRateLimitService) -> EmailRateLimitService {
        return service
    }
}
