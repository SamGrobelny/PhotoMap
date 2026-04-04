import Foundation
import Combine
import OSLog
internal import Auth
import Supabase

@MainActor
final class LeaderboardViewModel: ObservableObject {

    @Published private(set) var rows: [LeaderboardRow] = []
    @Published private(set) var friendIds: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentUserId: UUID?
    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "LeaderboardViewModel")

    // MARK: - Load

    func load() async {
        currentUserId = supabase.auth.currentSession?.user.id
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let rowsFetch: [LeaderboardRow] = supabase
                .from("leaderboard")
                .select()
                .order("points_all_time", ascending: false)
                .execute()
                .value

            async let friendsFetch = loadFriendIds()

            rows = try await rowsFetch
            await friendsFetch
            logger.info("Loaded \(self.rows.count) leaderboard entries, \(self.friendIds.count) friends")
        } catch {
            logger.error("Failed to load leaderboard: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    private func loadFriendIds() async {
        guard let userId = currentUserId else { return }
        do {
            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("requester_id.eq.\(userId),addressee_id.eq.\(userId)")
                .execute()
                .value

            friendIds = Set(friendships
                .filter { $0.status == .accepted }
                .map { $0.requesterId == userId ? $0.addresseeId : $0.requesterId }
            )
        } catch {
            logger.error("Failed to load friend IDs: \(error.localizedDescription)")
        }
    }

    // MARK: - Entries

    /// All users ranked for the given period.
    func entries(for period: LeaderboardScreen.Period) -> [LeaderboardEntry] {
        ranked(rows: rows, period: period)
    }

    /// Only the current user and their accepted friends, ranked for the given period.
    func friendEntries(for period: LeaderboardScreen.Period) -> [LeaderboardEntry] {
        guard let currentId = currentUserId else { return [] }
        let relevantIds = friendIds.union([currentId])
        let filtered = rows.filter { relevantIds.contains($0.userId) }
        return ranked(rows: filtered, period: period)
    }

    // MARK: - Helpers

    private func ranked(rows: [LeaderboardRow], period: LeaderboardScreen.Period) -> [LeaderboardEntry] {
        let sorted = rows.sorted { points($0, period) > points($1, period) }
        return sorted.enumerated().map { index, row in
            LeaderboardEntry(
                id: row.userId,
                rank: index + 1,
                name: row.username,
                points: points(row, period),
                isCurrentUser: row.userId == currentUserId
            )
        }
    }

    private func points(_ row: LeaderboardRow, _ period: LeaderboardScreen.Period) -> Int {
        switch period {
        case .week:    return row.pointsWeek
        case .month:   return row.pointsMonth
        case .allTime: return row.pointsAllTime
        }
    }
}
