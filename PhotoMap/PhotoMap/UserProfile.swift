//
//  UserProfile.swift
//  PhotoMap
//
//  Created on 3/13/26.
//
import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let username: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case createdAt = "created_at"
    }
}
