import Foundation

// MARK: - challenges table

struct ChallengeRow: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let difficulty: Int  // 1 = Easy, 2 = Medium, 3 = Hard
    let goal: Int
    let unit: String
    let typeId: Int

    enum CodingKeys: String, CodingKey {
        case id, title, description, difficulty, goal, unit
        case typeId = "type_id"
    }
}

// MARK: - user_challenges table (with embedded challenge via Supabase join)
// Note: user_challenges has no id column — challengeId serves as the Identifiable key.

struct UserChallengeWithDetails: Codable, Identifiable {
    var id: UUID { challengeId }  // computed — satisfies Identifiable without a DB column

    let userId: UUID
    let challengeId: UUID
    let progress: Int
    let isCompleted: Bool
    let assignedAt: Date
    let expiresAt: Date
    let challenges: ChallengeRow  // embedded via select("*, challenges(*)")

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case challengeId = "challenge_id"
        case progress
        case isCompleted = "is_completed"
        case assignedAt = "assigned_at"
        case expiresAt = "expires_at"
        case challenges
    }
}

// MARK: - Insert payload for user_challenges
// expires_at is intentionally omitted — a DB trigger computes it from the challenge type.

struct NewUserChallenge: Encodable {
    let userId: UUID
    let challengeId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case challengeId = "challenge_id"
    }
}
