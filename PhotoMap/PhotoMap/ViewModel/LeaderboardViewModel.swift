import Foundation
import Combine
import OSLog
internal import Auth
import Supabase

@MainActor
final class LeaderboardViewModel: ObservableObject {

    @Published private(set) var rows: [LeaderboardRow] = []
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
            // Fetch all rows sorted by all-time points descending.
            // Period switching is handled client-side from the cached rows.
            rows = try await supabase
                .from("leaderboard")
                .select()
                .order("points_all_time", ascending: false)
                .execute()
                .value
            logger.info("Loaded \(self.rows.count) leaderboard entries")
        } catch {
            logger.error("Failed to load leaderboard: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Entries for Period

    /// Returns ranked entries for the given period, re-sorted by that period's points.
    func entries(for period: LeaderboardScreen.Period) -> [LeaderboardEntry] {
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
