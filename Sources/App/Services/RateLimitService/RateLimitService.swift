import Vapor

// TODO: Test out `EmailRateLimitService().emailsSent()` method
// TODO: Write tests for all rate limit services code

struct RateLimitService {
    static func emailsService(_ service: EmailRateLimitService) -> EmailRateLimitService {
        return service
    }
}
