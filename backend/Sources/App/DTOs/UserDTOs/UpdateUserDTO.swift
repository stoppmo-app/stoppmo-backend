import Vapor

struct UpdateUserDTO: Content {
    var firstName : String?
    var lastName : String?
    var username : String?
    var profilePictureURL : String?
    var bio : String?
    var dateOfBirth : String?
    var password : String?
    var phoneNumber : String?
}