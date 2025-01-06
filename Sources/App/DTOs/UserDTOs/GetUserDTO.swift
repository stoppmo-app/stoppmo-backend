// GetUserDTO.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

struct GetUserDTO: Content {
    var id: UUID?
    var firstName: String
    var lastName: String
    var username: String
    var profilePictureURL: String
    var bio: String
    var dateOfBirth: Date
    var updatedAt: Date?
}
