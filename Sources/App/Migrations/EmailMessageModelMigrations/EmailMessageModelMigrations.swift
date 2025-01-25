import Fluent

struct EmailMessageModelMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateEmailMessageModel(), EmailMessageModelWithSentToAndSentFromEmail(),
        EmailMessageModelWithEmailMessageTypeEnum(), EmailMessageModelWithSubjectAndContent(),
        EmailMessageModelWithTimestampzSentAt()
    ]
}
