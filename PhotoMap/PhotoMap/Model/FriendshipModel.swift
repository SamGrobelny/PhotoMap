import Foundation

// MARK: - Friendship Status

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
    case declined
}

// MARK: - friendships table

struct Friendship: Codable {
    let requesterId: UUID
    let addresseeId: UUID
    let status: FriendshipStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
        case createdAt = "created_at"
    }
}

// MARK: - friends view
// select * from friends

struct FriendEntry: Codable, Identifiable {
    var id: UUID { friendId }
    let friendId: UUID

    enum CodingKeys: String, CodingKey {
        case friendId = "friend_id"
    }
}

// MARK: - friend_requests view
// select * from friend_requests
// Represents an incoming pending request from another user.

struct FriendRequest: Codable, Identifiable {
    var id: UUID { fromUserId }
    let fromUserId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case fromUserId = "from_user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Friend with profile info
// Used when showing a friend list with names

struct FriendProfile: Codable, Identifiable {
    var id: UUID { friendId }
    let friendId: UUID
    let username: String

    enum CodingKeys: String, CodingKey {
        case friendId = "friend_id"
        case username
    }
}

// MARK: - Send friend request
// Used when sending a friend request. Requester_id is set by RLS from auth.uid()

struct NewFriendRequest: Encodable {
    let addresseeId: UUID

    enum CodingKeys: String, CodingKey {
        case addresseeId = "addressee_id"
    }
}

// MARK: - Update payload
// Used when accepting or declining a request

struct FriendshipStatusUpdate: Encodable {
    let status: FriendshipStatus
}
