import Foundation
import OSLog
internal import Auth
import Supabase

extension Notification.Name {
    static let challengeProgressUpdated = Notification.Name("challengeProgressUpdated")
}

protocol ChallengeProgressServicing: Sendable {
    func recordPhoto(
        latitude: Double,
        longitude: Double,
        caption: String,
        timestamp: Date,
        priorPhotos: [PhotoHistoryEntry]
    ) async -> [String]
}

final class ChallengeProgressService: ChallengeProgressServicing {

    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "ChallengeProgressService")

    func recordPhoto(
        latitude: Double,
        longitude: Double,
        caption: String,
        timestamp: Date,
        priorPhotos: [PhotoHistoryEntry]
    ) async -> [String] {
        guard let userId = supabase.auth.currentSession?.user.id else {
            logger.warning("No authenticated user, skipping challenge progress update")
            return []
        }

        let active: [UserChallengeWithDetails]
        do {
            active = try await supabase
                .from("user_challenges")
                .select("*, challenges(*)")
                .eq("user_id", value: userId)
                .eq("is_completed", value: false)
                .execute()
                .value
        } catch {
            logger.error("Failed to fetch active challenges: \(error.localizedDescription)")
            return []
        }

        var completedTitles: [String] = []
        var anyWritten = false

        for uc in active where uc.assignedAt <= timestamp {
            guard let type = ChallengeType(rawValue: uc.challenges.behaviorId) else {
                logger.warning("Unknown challenge behavior_id \(uc.challenges.behaviorId), skipping")
                continue
            }

            // Pre-existing photos (taken before this challenge was assigned) do not count.
            let history = priorPhotos.filter { $0.timestamp >= uc.assignedAt && $0.timestamp < timestamp }

            let delta = type.delta(
                latitude: latitude,
                longitude: longitude,
                caption: caption,
                timestamp: timestamp,
                priorPhotos: history
            )
            guard delta > 0 else { continue }

            let newProgress = uc.progress + delta
            do {
                try await supabase
                    .from("user_challenges")
                    .update(["progress": newProgress])
                    .eq("user_id", value: userId)
                    .eq("challenge_id", value: uc.challengeId)
                    .execute()
                anyWritten = true
                logger.info("Advanced \(uc.challenges.title) to \(newProgress)/\(uc.challenges.goal)")

                if newProgress >= uc.challenges.goal {
                    completedTitles.append(uc.challenges.title)
                }
            } catch {
                logger.error("Failed to update progress for \(uc.challengeId): \(error.localizedDescription)")
            }
        }

        if anyWritten {
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .challengeProgressUpdated,
                    object: nil,
                    userInfo: ["completedTitles": completedTitles]
                )
            }
        }

        return completedTitles
    }
}
