// MigrationUtils.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

public extension Migrations {
    func addGroup(_ group: any MigrationsGroup, to id: DatabaseID? = nil) {
        for migration in group.migrations {
            add(migration, to: id)
        }
    }
}
