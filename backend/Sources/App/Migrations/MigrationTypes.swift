import Fluent

public protocol MigrationsGroup {
    var migrations : [any Migration] { get set }
}