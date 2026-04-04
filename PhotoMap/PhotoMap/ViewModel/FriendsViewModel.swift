internal import Auth
import Combine
import Foundation
import OSLog
import Supabase

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var pendingRequests: [UserProfile] = []
    @Published private(set) var searchResults: [UserProfile] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?

    private(set) var currentUserId: UUID?
    private var allFriendships: [Friendship] = []
    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "FriendsViewModel")

    // MARK: - Relationship Status

    enum RelationshipStatus {
        case none
        case requestSent
        case requestReceived
        case friends
    }

    func relationship(with userId: UUID) -> RelationshipStatus {
        guard let currentId = currentUserId else { return .none }
        guard let f = allFriendships.first(where: {
            ($0.requesterId == userId && $0.addresseeId == currentId) ||
                ($0.requesterId == currentId && $0.addresseeId == userId)
        }) else { return .none }

        switch f.status {
        case .accepted: return .friends
        case .pending: return f.requesterId == currentId ? .requestSent : .requestReceived
        case .declined: return .none
        }
    }

    // MARK: - Load

    func load() async {
        guard let userId = supabase.auth.currentSession?.user.id else { return }
        currentUserId = userId
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // all rows where current user is either side
            allFriendships = try await supabase
                .from("friendships")
                .select()
                .or("requester_id.eq.\(userId),addressee_id.eq.\(userId)")
                .execute()
                .value

            // Accepted friends
            let friendIds = allFriendships
                .filter { $0.status == .accepted }
                .map { $0.requesterId == userId ? $0.addresseeId : $0.requesterId }

            friends = friendIds.isEmpty ? [] : try await supabase
                .from("profiles")
                .select()
                .in("id", values: friendIds)
                .execute()
                .value

            // Pending incoming requests
            let requesterIds = allFriendships
                .filter { $0.status == .pending && $0.addresseeId == userId }
                .map { $0.requesterId }

            pendingRequests = requesterIds.isEmpty ? [] : try await supabase
                .from("profiles")
                .select()
                .in("id", values: requesterIds)
                .execute()
                .value

            logger.info("Loaded \(self.friends.count) friends, \(self.pendingRequests.count) pending requests")
        } catch {
            logger.error("Failed to load friends data: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Search

    func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        guard let userId = supabase.auth.currentSession?.user.id else { return }

        isSearching = true
        defer { isSearching = false }

        do {
            let results: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .ilike("username", pattern: "%\(trimmed)%")
                .neq("id", value: userId)
                .limit(20)
                .execute()
                .value

            guard !Task.isCancelled else { return }
            searchResults = results
        } catch {
            if !Task.isCancelled {
                logger.error("Search failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Send Request

    func sendRequest(to userId: UUID) async {
        guard let currentId = currentUserId ?? supabase.auth.currentSession?.user.id else { return }
        do {
            try await supabase
                .from("friendships")
                .insert(NewFriendRequest(requesterId: currentId, addresseeId: userId))
                .execute()

            allFriendships.append(Friendship(
                requesterId: currentId,
                addresseeId: userId,
                status: .pending,
                createdAt: Date()
            ))
            logger.info("Friend request sent to \(userId)")
        } catch {
            logger.error("Failed to send request: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Accept Request

    func accept(from userId: UUID) async {
        guard let currentId = currentUserId else { return }
        do {
            try await supabase
                .from("friendships")
                .update(FriendshipStatusUpdate(status: .accepted))
                .eq("requester_id", value: userId)
                .eq("addressee_id", value: currentId)
                .execute()

            await load() // Refresh to move user from requests to friends
            logger.info("Accepted friend request from \(userId)")
        } catch {
            logger.error("Failed to accept request: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Decline Request

    func decline(from userId: UUID) async {
        guard let currentId = currentUserId else { return }
        do {
            try await supabase
                .from("friendships")
                .update(FriendshipStatusUpdate(status: .declined))
                .eq("requester_id", value: userId)
                .eq("addressee_id", value: currentId)
                .execute()

            pendingRequests.removeAll { $0.id == userId }
            if let idx = allFriendships.firstIndex(where: {
                $0.requesterId == userId && $0.addresseeId == currentId
            }) {
                allFriendships[idx] = Friendship(
                    requesterId: userId,
                    addresseeId: currentId,
                    status: .declined,
                    createdAt: allFriendships[idx].createdAt
                )
            }
            logger.info("Declined friend request from \(userId)")
        } catch {
            logger.error("Failed to decline request: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
