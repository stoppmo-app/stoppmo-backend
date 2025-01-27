import Fluent
import Foundation
import Vapor

final class KeyValuePairModel: Model, Authenticatable, @unchecked Sendable {
    static let schema = "key_value_pairs"

    @ID(key: .id)
    var id: UUID?

    @Enum(key: "pair_type")
    var pairType: KeyValuePairModelType

    @Field(key: "key")
    var key: String

    @Field(key: "value")
    var value: String

    @OptionalField(key: "metadata")
    var metadata: String?

    @OptionalParent(key: "user_id")
    var user: UserModel?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        pairType: KeyValuePairModelType,
        key: String,
        value: String,
        metadata: String? = nil,
        userID: UUID? = nil
    ) {
        self.id = id
        self.pairType = pairType
        self.key = key
        self.value = value
        self.metadata = metadata
        self.$user.id = userID
    }
}
