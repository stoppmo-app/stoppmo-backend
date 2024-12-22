import Fluent
import Vapor

struct BadgeDTO: Content {
    var id: UUID?
    var name: String?
    var description: String?
    var unlockAfterXDays: Int?
    
    func toModel() -> Badge {
        let model = Badge()

        model.id = self.id
        if let name = self.name {
            model.name = name
        }
        if let description = self.description {
            model.description = description
        }
        if let unlockAfterXDays = self.unlockAfterXDays {
            model.unlockAfterXDays = unlockAfterXDays
        }

        return model
    }
}