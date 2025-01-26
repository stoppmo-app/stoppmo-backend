// EmailMessageModelMigrations.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent

struct EmailMessageModelMigrations: MigrationsGroup {
    var migrations: [any Migration] = [
        CreateEmailMessageModel(), EmailMessageModelWithSentToAndSentFromEmail(),
        EmailMessageModelWithEmailMessageTypeEnum(), EmailMessageModelWithSubjectAndContent(),
        EmailMessageModelWithTimestampzSentAt(),
    ]
}
