import SwiftUI
internal import Auth
import Supabase

struct ProfileScreen: View {
    var onLogout: () -> Void

    @State private var profile: UserProfile?
    @State private var showSignOutAlert = false
    @State private var showingFriends = false
    @State private var selectedTab: ContentTab = .photos
    @StateObject private var friendsViewModel = FriendsViewModel()

    enum ContentTab: String, CaseIterable {
        case photos = "Photos"
        case challenges = "Challenges"
        case completed = "Completed"
    }

    // Stubbed stats — wire up to real data later
    private let photoCount = 0
    private let challengesCompleted = 0
    private let points = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    Divider()
                    friendsSection
                    Divider()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) { onLogout() }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingFriends) {
                FriendsScreen()
            }
            .task {
                await loadProfile()
                await friendsViewModel.load()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            avatarView

            if let profile {
                Text(profile.username)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 34)
            }

            if let createdAt = profile?.createdAt {
                Text("Member since \(createdAt.formatted(.dateTime.month(.wide).year()))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }


        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.75))
                .frame(width: 72, height: 72)
            Text(initials)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }

    private var initials: String {
        guard let username = profile?.username, !username.isEmpty else { return "?" }
        return String(username.prefix(2)).uppercased()
    }

    // MARK: - Friends Section

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Section header
            HStack {
                Text("Friends")
                    .font(.headline)
                if !friendsViewModel.pendingRequests.isEmpty {
                    // Pending request badge
                    Text("\(friendsViewModel.pendingRequests.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                Spacer()
                Button("Manage") { showingFriends = true }
                    .font(.subheadline)
            }

            // Pending requests
            if !friendsViewModel.pendingRequests.isEmpty {
                VStack(spacing: 8) {
                    ForEach(friendsViewModel.pendingRequests) { requester in
                        HStack(spacing: 10) {
                            FriendAvatarView(username: requester.username, size: 36)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(requester.username)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Sent you a friend request")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Decline") {
                                Task { await friendsViewModel.decline(from: requester.id) }
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .controlSize(.small)
                            Button("Accept") {
                                Task { await friendsViewModel.accept(from: requester.id) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .controlSize(.small)
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            // Friends list / empty state
            if friendsViewModel.isLoading {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if friendsViewModel.friends.isEmpty {
                Button {
                    showingFriends = true
                } label: {
                    Label("Add your first friend", systemImage: "person.badge.plus")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                // Horizontal avatar strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(friendsViewModel.friends) { friend in
                            VStack(spacing: 4) {
                                FriendAvatarView(username: friend.username, size: 48)
                                Text(friend.username)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .frame(width: 48)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Data

    private func loadProfile() async {
        guard let userId = supabase.auth.currentSession?.user.id else { return }
        do {
            profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
        } catch {
            // Screen still renders without profile data
        }
    }
}

// MARK: - Friend Avatar

private struct FriendAvatarView: View {
    let username: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: size, height: size)
            Text(String(username.prefix(2)).uppercased())
                .font(size >= 48 ? .subheadline : .caption)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - Stat View

private struct StatView: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value == 0 ? "—" : "\(value)")
                .font(.title3)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileScreen(onLogout: {})
}
