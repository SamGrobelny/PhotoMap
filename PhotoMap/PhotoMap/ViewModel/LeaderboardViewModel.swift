import Foundation
import Combine
import OSLog
internal import Auth
import Supabase

@MainActor
final class LeaderboardViewModel: ObservableObject {

    @Published private(set) var friendIds: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Pre-computed sorted entries. updated once when data loads
    @Published private(set) var entriesWeek:     [LeaderboardEntry] = []
    @Published private(set) var entriesMonth:    [LeaderboardEntry] = []
    @Published private(set) var entriesAllTime:  [LeaderboardEntry] = []
    @Published private(set) var friendEntriesWeek:    [LeaderboardEntry] = []
    @Published private(set) var friendEntriesMonth:   [LeaderboardEntry] = []
    @Published private(set) var friendEntriesAllTime: [LeaderboardEntry] = []

    private var rows: [LeaderboardRow] = []
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
                .execute()
                .value

            async let friendsFetch = loadFriendIds()

            rows = try await rowsFetch
            await friendsFetch
            recomputeEntries()
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

    func entries(for period: LeaderboardScreen.Period) -> [LeaderboardEntry] {
        switch period {
        case .week:    return entriesWeek
        case .month:   return entriesMonth
        case .allTime: return entriesAllTime
        }
    }

    func friendEntries(for period: LeaderboardScreen.Period) -> [LeaderboardEntry] {
        switch period {
        case .week:    return friendEntriesWeek
        case .month:   return friendEntriesMonth
        case .allTime: return friendEntriesAllTime
        }
    }

    // MARK: - Helpers

    private func recomputeEntries() {
        entriesWeek    = ranked(rows: rows, keyPath: \.pointsWeek)
        entriesMonth   = ranked(rows: rows, keyPath: \.pointsMonth)
        entriesAllTime = ranked(rows: rows, keyPath: \.pointsAllTime)

        let friendRows: [LeaderboardRow]
        if let currentId = currentUserId {
            let relevantIds = friendIds.union([currentId])
            friendRows = rows.filter { relevantIds.contains($0.userId) }
        } else {
            friendRows = []
        }

        friendEntriesWeek    = ranked(rows: friendRows, keyPath: \.pointsWeek)
        friendEntriesMonth   = ranked(rows: friendRows, keyPath: \.pointsMonth)
        friendEntriesAllTime = ranked(rows: friendRows, keyPath: \.pointsAllTime)
    }

    private func ranked(rows: [LeaderboardRow], keyPath: KeyPath<LeaderboardRow, Int>) -> [LeaderboardEntry] {
        rows.sorted { $0[keyPath: keyPath] > $1[keyPath: keyPath] }
            .enumerated()
            .map { index, row in
                LeaderboardEntry(
                    id: row.userId,
                    rank: index + 1,
                    name: row.username,
                    points: row[keyPath: keyPath],
                    isCurrentUser: row.userId == currentUserId
                )
            }
    }
}
