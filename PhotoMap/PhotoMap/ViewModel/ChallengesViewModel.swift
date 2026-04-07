import Foundation
import Combine
import OSLog
internal import Auth
import Supabase

@MainActor
final class ChallengesViewModel: ObservableObject {

    @Published private(set) var challenges: [Challenge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "ChallengesViewModel")

    // MARK: - Load

    func load() async {
        guard let userId = supabase.auth.currentSession?.user.id else {
            logger.warning("No authenticated user, skipping challenge load")
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let results: [UserChallengeWithDetails] = try await supabase
                .from("user_challenges")
                .select("*, challenges(*)")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            challenges = results.map(Challenge.init)

            let hasIncomplete = results.contains { !$0.isCompleted }
            if !hasIncomplete {
                // No active challenges. Assign a new batch
                try await assignChallenges(userId: userId)
            } else {
                logger.info("Loaded \(results.count) challenges")
            }
        } catch {
            logger.error("Failed to load challenges: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Assignment

    /// Fetches available challenges from the DB and assigns them to the user.
    /// Called automatically when a user has no active challenges.
    private func assignChallenges(userId: UUID) async throws {
        logger.info("No challenges found for user, assigning new ones")

        let available: [ChallengeRow] = try await supabase
            .from("challenges")
            .select()
            .limit(3)
            .execute()
            .value

        guard !available.isEmpty else {
            logger.warning("No challenges available in the database to assign")
            return
        }

        let inserts = available.map { challenge in
            NewUserChallenge(userId: userId, challengeId: challenge.id)
        }

        try await supabase.from("user_challenges").insert(inserts).execute()
        logger.info("Assigned \(inserts.count) challenges to user")

        // Reload to get the full joined data back
        let results: [UserChallengeWithDetails] = try await supabase
            .from("user_challenges")
            .select("*, challenges(*)")
            .eq("user_id", value: userId)
            .execute()
            .value

        challenges = results.map(Challenge.init)
    }
}
