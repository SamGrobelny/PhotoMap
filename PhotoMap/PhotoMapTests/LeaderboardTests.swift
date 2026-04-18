import XCTest
@testable import PhotoMap

final class LeaderboardTests: XCTestCase {

    // MARK: - Helpers

    private func makeEntry(name: String) -> LeaderboardEntry {
        LeaderboardEntry(id: UUID(), rank: 1, name: name, points: 100, isCurrentUser: false)
    }

    // MARK: - Tests

    /// A single-word username produces a single initial.
    func test_leaderboardEntry_initialsFromSingleWord() {
        let entry = makeEntry(name: "Alice")
        XCTAssertEqual(entry.initials, "A")
    }

    /// Only the first two words contribute to initials, even for longer names.
    func test_leaderboardEntry_initialsLimitedToTwo() {
        let entry = makeEntry(name: "Alice Bob Charlie")
        XCTAssertEqual(entry.initials, "AB")
    }
}
