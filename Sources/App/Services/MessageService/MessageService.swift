import Fluent
import Vapor

struct MessageService {
    static func getEmail(_ service: EmailService) -> EmailService {
        return service
    }
}
