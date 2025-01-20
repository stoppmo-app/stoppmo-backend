import Fluent

struct AuthenticationCodeModelMigrations: MigrationsGroup {
    var migrations: [any Migration] = [CreateAuthenticationCodeModel()]
}
