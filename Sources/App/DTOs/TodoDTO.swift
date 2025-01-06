// TodoDTO.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Fluent
import Vapor

struct TodoDTO: Content {
    var id: UUID?
    var title: String?

    func toModel() -> Todo {
        let model = Todo()

        model.id = id
        if let title {
            model.title = title
        }
        return model
    }
}
