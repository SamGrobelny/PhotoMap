import XCTest
@testable import PhotoMap

final class FriendsTests: XCTestCase {

    // MARK: - Tests

    /// FriendshipStatus raw values match the strings stored in the database.
    func test_friendshipStatus_rawValues() {
        XCTAssertEqual(FriendshipStatus.pending.rawValue,  "pending")
        XCTAssertEqual(FriendshipStatus.accepted.rawValue, "accepted")
        XCTAssertEqual(FriendshipStatus.declined.rawValue, "declined")
    }

    /// FriendshipStatus decodes correctly from a JSON string produced by Supabase.
    func test_friendshipStatus_jsonDecoding() throws {
        let json = Data("\"accepted\"".utf8)
        let status = try JSONDecoder().decode(FriendshipStatus.self, from: json)
        XCTAssertEqual(status, .accepted)
    }
}
