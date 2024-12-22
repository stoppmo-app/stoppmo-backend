import Fluent
import Vapor

struct UserBadgeDTO: Content {
    var id: UUID?
    var startedAt: Date?
    var badgeID: UUID?
    var userID: UUID?
    
    func toModel() -> UserBadge {
        let model = UserBadge()
        
        model.id = self.id

        if let startedAt = self.startedAt {
            model.startedAt = startedAt
        }
        if let badgeID = self.badgeID {
            model.$badge.id = badgeID
        }
        if let userID = self.userID {
            model.$user.id = userID
        }

        return model
    }
}
