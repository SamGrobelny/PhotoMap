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
        case .requestSent:
            Text("Pending")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        case .requestReceived:
            Button("Accept", action: onAccept)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)
        case .friends:
            Image(systemName: "checkmark")
                .foregroundStyle(.secondary)
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
            Button("Accept", action: onAccept)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)
        }
        .padding(.vertical, 2)
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
    }
}

// MARK: - Avatar

private struct AvatarView: View {
    let username: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: size, height: size)
            Text(String(username.prefix(2)).uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - Preview

#Preview {
    FriendsScreen()
}
