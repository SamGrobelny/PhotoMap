import XCTest
@testable import PhotoMap

final class ChallengesTests: XCTestCase {

    // MARK: - Helpers

    private func makeUserChallenge(
        progress: Int,
        goal: Int,
        isCompleted: Bool = false,
        difficulty: Int = 1
    ) -> UserChallengeWithDetails {
        let row = ChallengeRow(
            id: UUID(),
            title: "Test Challenge",
            description: "Take photos outdoors",
            difficulty: difficulty,
            goal: goal,
            unit: "photos",
            typeId: 1
        )
        return UserChallengeWithDetails(
            userId: UUID(),
            challengeId: UUID(),
            progress: progress,
            isCompleted: isCompleted,
            assignedAt: Date(),
            expiresAt: Date().addingTimeInterval(86_400),
            challenges: row
        )
    }

    // MARK: - Tests

    /// Progress is correctly computed as current / goal (0.0 – 1.0).
    func test_challengeProgress_midway() {
        let uc = makeUserChallenge(progress: 5, goal: 10)
        let challenge = Challenge(from: uc)

        XCTAssertEqual(challenge.progress, 0.5, accuracy: 0.001)
    }

    /// Progress is clamped to 1.0 even when current exceeds goal.
    func test_challengeProgress_clampedAtOne() {
        let uc = makeUserChallenge(progress: 15, goal: 10)
        let challenge = Challenge(from: uc)

        XCTAssertEqual(challenge.progress, 1.0, accuracy: 0.001)
    }
}
