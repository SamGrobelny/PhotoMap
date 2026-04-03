import Foundation

// MARK: - leaderboard view (DB)

struct LeaderboardRow: Codable {
    let userId: UUID
    let username: String
    let pointsWeek: Int
    let pointsMonth: Int
    let pointsAllTime: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case pointsWeek = "points_week"
        case pointsMonth = "points_month"
        case pointsAllTime = "points_all_time"
    }
}

// MARK: - Display Model

struct LeaderboardEntry: Identifiable {
    let id: UUID          
    let rank: Int
    let name: String
    let points: Int
    let isCurrentUser: Bool

    var initials: String {
        let parts = name.split(separator: " ")
        return parts.compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
}
