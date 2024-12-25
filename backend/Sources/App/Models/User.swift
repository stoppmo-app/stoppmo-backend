import Fluent
import Foundation

enum Role: String, Codable {
    case admin, member
}

final class User: Model, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @Field(key: "username")
    var username: String

    @Field(key: "password")
    var password: String

    @Enum(key: "role")
    var role: Role

    @Field(key: "profile_picture_url")
    var profilePictureURL: String

    @Field(key: "bio")
    var bio: String

    @Field(key: "phone_number")
    var phoneNumber: String

    @Field(key: "date_of_birth")
    var dateOfBirth: Date

    @Children(for: \.$user)
    var badgesHistory: [UserBadge]

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?


    init() { }

    init(
        id: UUID? = nil,
        name: String,
        surname: String,
        username: String,
        password: String,
        role: Role,
        profilePictureURL: String,
        bio: String,
        phoneNumber: String,
        dateOfBirth: Date
    ) {
        self.id = id
        self.firstName = name
        self.lastName = surname
        self.username = username
        self.password = password
        self.role = role
        self.profilePictureURL = profilePictureURL
        self.bio = bio
        self.phoneNumber = phoneNumber
        self.dateOfBirth = dateOfBirth
    }
}
