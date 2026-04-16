import SwiftUI

// MARK: - Screen

struct LeaderboardScreen: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var selectedScope: Scope = .everyone
    @State private var selectedPeriod: Period = .week
    @State private var showingFriends = false

    enum Scope: String, CaseIterable {
        case everyone = "Everyone"
        case friends = "Friends"
    }

    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
    }

    private var entries: [LeaderboardEntry] {
        switch selectedScope {
        case .everyone: return viewModel.entries(for: selectedPeriod)
        case .friends:  return viewModel.friendEntries(for: selectedPeriod)
        }
    }

    private var topThree: [LeaderboardEntry] { Array(entries.prefix(3)) }
    private var remaining: [LeaderboardEntry] { Array(entries.dropFirst(3)) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Scope", selection: $selectedScope) {
                    ForEach(Scope.allCases, id: \.self) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])
                .accessibilityLabel("Leaderboard scope")
                .accessibilityHint("Select to show everyone or just friends")

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .accessibilityLabel("Time period")
                .accessibilityHint("Select week, month, or all time rankings")

                if selectedScope == .friends && viewModel.friendIds.isEmpty && !viewModel.isLoading {
                    Spacer()
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2",
                        description: Text("Add friends to compare scores with them.")
                    )
                    Button("Add Friends") { showingFriends = true }
                        .buttonStyle(.borderedProminent)
                    Spacer()
                } else if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading Leaderboard...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    ContentUnavailableView(
                        "Couldn't Load Leaderboard",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                    Spacer()
                } else if entries.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Rankings Yet",
                        systemImage: "trophy",
                        description: Text("Complete challenges to earn points and appear here.")
                    )
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            PodiumView(topThree: topThree)
                                .padding(.top, 8)

                            VStack(spacing: 8) {
                                ForEach(remaining) { entry in
                                    LeaderboardRowView(entry: entry)
                                }
                            }
                            .padding(.horizontal)

                            Button {
                                showingFriends = true
                            } label: {
                                Label("Add Friends", systemImage: "person.badge.plus")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .task {
                await viewModel.load()
            }
            .sheet(isPresented: $showingFriends) {
                FriendsScreen()
            }
        }
    }
}

// MARK: - Podium

private struct PodiumView: View {
    let topThree: [LeaderboardEntry]

    // Dynamic Type support for podium heights
    @ScaledMetric(relativeTo: .body) private var podiumHeightFirst: CGFloat = 90
    @ScaledMetric(relativeTo: .body) private var podiumHeightSecond: CGFloat = 60
    @ScaledMetric(relativeTo: .body) private var podiumHeightThird: CGFloat = 45

    // Dynamic Type support for avatar sizes
    @ScaledMetric(relativeTo: .body) private var avatarSizeFirst: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var avatarSizeOther: CGFloat = 50

    // Display order: 2nd, 1st, 3rd
    private var podiumOrder: [LeaderboardEntry] {
        guard topThree.count == 3 else { return topThree }
        return [topThree[1], topThree[0], topThree[2]]
    }

    private func podiumHeight(for rank: Int) -> CGFloat {
        switch rank {
        case 1: return podiumHeightFirst
        case 2: return podiumHeightSecond
        default: return podiumHeightThird
        }
    }

    private func avatarSize(for rank: Int) -> CGFloat { rank == 1 ? avatarSizeFirst : avatarSizeOther }

    private func avatarColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        default: return .brown
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(podiumOrder) { entry in
                VStack(spacing: 6) {
                    if entry.rank == 1 {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                            .font(.title3)
                            .accessibilityHidden(true)
                    }

                    ZStack {
                        Circle()
                            .fill(avatarColor(for: entry.rank))
                            .frame(width: avatarSize(for: entry.rank),
                                   height: avatarSize(for: entry.rank))
                        Text(entry.initials)
                            .font(entry.rank == 1 ? .headline : .subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                    Text(entry.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text("\(entry.points) pts")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(avatarColor(for: entry.rank).opacity(0.2))
                            .frame(width: 90, height: podiumHeight(for: entry.rank))
                        Text("\(entry.rank)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(avatarColor(for: entry.rank))
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Rank \(entry.rank), \(entry.name), \(entry.points) points")
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Row

private struct LeaderboardRowView: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("\(entry.rank)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            ZStack {
                Circle()
                    .fill(entry.isCurrentUser ? Color.blue : Color(.systemGray4))
                    .frame(width: 36, height: 36)
                Text(entry.initials)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(entry.isCurrentUser ? .white : .primary)
            }

            Text(entry.name)
                .font(.subheadline)
                .fontWeight(entry.isCurrentUser ? .semibold : .regular)

            Spacer()

            Text("\(entry.points) pts")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(entry.isCurrentUser ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(entry.isCurrentUser ? Color.blue.opacity(0.4) : .clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(entry.rank), \(entry.name), \(entry.points) points")
        .accessibilityHint(entry.isCurrentUser ? "This is you" : "")
    }
}

// MARK: - Preview

#Preview {
    LeaderboardScreen()
}
