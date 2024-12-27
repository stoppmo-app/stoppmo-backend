import Vapor
import Fluent

extension Migrations {
    public func addGroup(_ group: any MigrationsGroup, to id: DatabaseID? = nil) { 
        for migration in group.migrations {
            self.add(migration, to: id)
        }
    }
}