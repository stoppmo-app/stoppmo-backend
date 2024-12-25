import Fluent
import Foundation

final class Badge: Model, @unchecked Sendable {
    static let schema = "badges"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "description")
    var description: String

    @Field(key: "unlock_after_x_days")
    var unlockAfterXDays: Int

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(
        id: UUID? = nil,
        name: String,
        description: String,
        unlockAfterXDays: Int
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.unlockAfterXDays = unlockAfterXDays
    }

    func toDTO() -> BadgeDTO.GetBadge {
        return .init(name: self.name, description: self.description, unlockAfterXDays: self.unlockAfterXDays)
    }
}
