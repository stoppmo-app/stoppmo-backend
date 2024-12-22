import Fluent
import Vapor

struct UserDTO: Content {
    var id: UUID?
    var name: String?
    var surname: String?
    var username: String?
    var password: String?
    var userRole: UserRole?
    
    func toModel() -> User {
        let model = User()

        model.id = self.id

        if let name = self.name {
            model.name = name
        }
        if let surname = self.surname {
            model.surname = surname
        }
        if let username = self.username {
            model.username = username
        }
        if let password = self.password {
            model.password = password
        }
        if let userRole = self.userRole {
            model.userRole = userRole
        }

        return model
    }
}