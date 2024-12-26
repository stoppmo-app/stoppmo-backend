import Vapor

struct GetUserDTO: Content {
    var firstName : String
    var lastName : String
    var username : String
    var profilePictureURL : String
    var bio : String
    var dateOfBirth : Date
    var updatedAt: Date?
}