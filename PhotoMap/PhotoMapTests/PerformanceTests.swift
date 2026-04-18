import XCTest
import SwiftData
import CoreLocation
@testable import PhotoMap

@MainActor
final class PerformanceTests: XCTestCase {

    private let options: XCTMeasureOptions = {
        let o = XCTMeasureOptions()
        o.iterationCount = 5
        return o
    }()

    // MARK: - Challenges

    /// Measures how long it takes to filter 50 challenges into active vs completed lists.
    /// Called on every render of ChallengesScreen.
    func test_challenges_filterByStatus() {
        let challenges = makeChallenges(count: 50)

        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: options) {
            _ = challenges.filter { !$0.isCompleted }
            _ = challenges.filter {  $0.isCompleted }
        }
    }

    /// Measures mapping 50 raw Supabase rows into Challenge display models.
    /// Happens every time ChallengesViewModel.load() completes.
    func test_challenges_mapRowsToModels() {
        let rows = makeUserChallengeRows(count: 50)

        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: options) {
            _ = MainActor.assumeIsolated { rows.map(Challenge.init) }
        }
    }

    // MARK: - Leaderboard

    /// Measures sorting and mapping 200 leaderboard rows into ranked display entries.
    /// Called by LeaderboardViewModel.entries(for:) on every period switch.
    func test_leaderboard_rankEntries() {
        let rows = makeLeaderboardRows(count: 200)

        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric(), XCTClockMetric()], options: options) {
            _ = ranked(rows: rows, by: \.pointsAllTime)
        }
    }

    /// Measures filtering rows to friends-only then ranking them.
    /// Called by LeaderboardViewModel.friendEntries(for:).
    func test_leaderboard_filterAndRankFriends() {
        let rows = makeLeaderboardRows(count: 200)
        let friendIds = Set(rows.prefix(40).map { $0.userId })

        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: options) {
            let filtered = rows.filter { friendIds.contains($0.userId) }
            _ = ranked(rows: filtered, by: \.pointsAllTime)
        }
    }

    // MARK: - Helpers

    private func makeChallenges(count: Int) -> [Challenge] {
        MainActor.assumeIsolated { makeUserChallengeRows(count: count).map(Challenge.init) }
    }

    private func makeUserChallengeRows(count: Int) -> [UserChallengeWithDetails] {
        (0..<count).map { i in
            let row = ChallengeRow(
                id: UUID(), title: "Challenge \(i)", description: "Desc \(i)",
                difficulty: (i % 3) + 1, goal: 10, unit: "photos", typeId: 1
            )
            return UserChallengeWithDetails(
                userId: UUID(), challengeId: row.id,
                progress: i % 10, isCompleted: i % 4 == 0,
                assignedAt: Date(),
                expiresAt: Date().addingTimeInterval(86_400),
                challenges: row
            )
        }
    }

    private func makeLeaderboardRows(count: Int) -> [LeaderboardRow] {
        (0..<count).map { i in
            LeaderboardRow(
                userId: UUID(), username: "user\(i)",
                pointsWeek:    (i * 7)   % 1_000,
                pointsMonth:   (i * 31)  % 5_000,
                pointsAllTime: (i * 200) % 100_000
            )
        }
    }

    private func makeProcessedPhotos(count: Int) -> [ProcessedPhoto] {
        (0..<count).map { i in
            ProcessedPhoto(
                imageData: Data(),
                location: CLLocationCoordinate2D(latitude: Double(i), longitude: Double(i)),
                timestamp: Date(),
                caption: "Photo \(i)"
            )
        }
    }

    private func ranked(rows: [LeaderboardRow], by keyPath: KeyPath<LeaderboardRow, Int>) -> [LeaderboardEntry] {
        rows.sorted { $0[keyPath: keyPath] > $1[keyPath: keyPath] }
            .enumerated()
            .map { index, row in
                LeaderboardEntry(
                    id: row.userId, rank: index + 1,
                    name: row.username, points: row[keyPath: keyPath],
                    isCurrentUser: false
                )
            }
    }
}
