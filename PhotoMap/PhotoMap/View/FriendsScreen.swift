import SwiftUI

struct FriendsScreen: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var searchQuery = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if !searchQuery.isEmpty {
                    searchResultsView
                } else {
                    friendsListView
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .searchable(text: $searchQuery, prompt: "Search by username")
            .task(id: searchQuery) {
                await viewModel.search(query: searchQuery)
            }
            .task {
                await viewModel.load()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        List(viewModel.searchResults) { profile in
            SearchResultRow(
                profile: profile,
                status: viewModel.relationship(with: profile.id),
                onAdd:    { Task { await viewModel.sendRequest(to: profile.id) } },
                onAccept: { Task { await viewModel.accept(from: profile.id) } }
            )
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.isSearching {
                ProgressView()
            } else if viewModel.searchResults.isEmpty {
                ContentUnavailableView.search(text: searchQuery)
            }
        }
    }

    // MARK: - Friends + Requests List

    private var friendsListView: some View {
        List {
            if !viewModel.pendingRequests.isEmpty {
                Section("Requests") {
                    ForEach(viewModel.pendingRequests) { profile in
                        PendingRequestRow(
                            profile: profile,
                            onAccept: { Task { await viewModel.accept(from: profile.id) } },
                            onDecline: { Task { await viewModel.decline(from: profile.id) } }
                        )
                    }
                }
            }

            if !viewModel.outgoingRequests.isEmpty {
                Section("Sent") {
                    ForEach(viewModel.outgoingRequests) { profile in
                        OutgoingRequestRow(
                            profile: profile,
                            onCancel: { Task { await viewModel.cancelRequest(to: profile.id) } }
                        )
                    }
                }
            }

            Section("Friends") {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if viewModel.friends.isEmpty {
                    Text("Search for someone above to add a friend.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(viewModel.friends) { profile in
                        FriendRow(profile: profile)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let profile: UserProfile
    let status: FriendsViewModel.RelationshipStatus
    let onAdd: () -> Void
    let onAccept: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(username: profile.username, size: 40)
            Text(profile.username)
                .font(.subheadline)
            Spacer()
            actionView
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var actionView: some View {
        switch status {
        case .none:
            Button("Add", action: onAdd)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityLabel("Add \(profile.username) as friend")
                .accessibilityHint("Send a friend request")
        case .requestSent:
            Text("Pending")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
                .accessibilityLabel("Friend request pending")
                .accessibilityHint("Waiting for \(profile.username) to respond")
        case .requestReceived:
            Button("Accept", action: onAccept)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)
                .accessibilityLabel("Accept friend request from \(profile.username)")
        case .friends:
            Image(systemName: "checkmark")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Already friends with \(profile.username)")
        }
    }
}

// MARK: - Pending Request Row

private struct PendingRequestRow: View {
    let profile: UserProfile
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(username: profile.username, size: 40)
            Text(profile.username)
                .font(.subheadline)
            Spacer()
            Button("Decline", action: onDecline)
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
                .accessibilityLabel("Decline request from \(profile.username)")
            Button("Accept", action: onAccept)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)
                .accessibilityLabel("Accept request from \(profile.username)")
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Friend request from \(profile.username)")
    }
}

// MARK: - Outgoing Request Row

private struct OutgoingRequestRow: View {
    let profile: UserProfile
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(username: profile.username, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.username)
                    .font(.subheadline)
                Text("Pending")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
                .accessibilityLabel("Cancel request to \(profile.username)")
                .accessibilityHint("Withdraw your pending friend request")
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Outgoing request to \(profile.username), pending")
    }
}

// MARK: - Friend Row

private struct FriendRow: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(username: profile.username, size: 40)
            Text(profile.username)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Friend: \(profile.username)")
    }
}

// MARK: - Avatar

private struct AvatarView: View {
    let username: String
    let size: CGFloat

    // Dynamic Type support for avatar size
    @ScaledMetric private var scaledSize: CGFloat = 40

    var body: some View {
        let displaySize = size == 40 ? scaledSize : size
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: displaySize, height: displaySize)
            Text(String(username.prefix(2)).uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    FriendsScreen()
}
