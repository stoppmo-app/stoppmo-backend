// CreateUserDTO.swift
// Copyright (c) 2025 StopPMO
// All source code and related assets are the property of StopPMO.
// All rights reserved.

import Vapor

struct CreateUserDTO: Content {
    var firstName: String
    var lastName: String
    var username: String
    var email: String
    var passwordHash: String
    var profilePictureURL: String
    var bio: String
    var dateOfBirth: Date
    var phoneNumber: String
}
