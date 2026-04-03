import SwiftUI

// MARK: - Model

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let points: Int
    let isCurrentUser: Bool

    var initials: String {
        let parts = name.split(separator: " ")
        return parts.compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
}

// MARK: - Sample Data

private let sampleEntries: [LeaderboardEntry] = [
    LeaderboardEntry(rank: 1, name: "John S.",  points: 1000, isCurrentUser: false),
    LeaderboardEntry(rank: 2, name: "John S.",  points: 1000, isCurrentUser: false),
    LeaderboardEntry(rank: 3, name: "Jake B.",  points: 800,  isCurrentUser: false),
    LeaderboardEntry(rank: 4, name: "You",      points: 750,  isCurrentUser: true),
    LeaderboardEntry(rank: 5, name: "John S.",  points: 700,  isCurrentUser: false),
    LeaderboardEntry(rank: 6, name: "Stan S.",  points: 650,  isCurrentUser: false),
]

// MARK: - Screen

struct LeaderboardScreen: View {
    @State private var selectedPeriod: Period = .week

    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
    }

    private var topThree: [LeaderboardEntry] {
        Array(sampleEntries.prefix(3))
    }

    private var remainingEntries: [LeaderboardEntry] {
        Array(sampleEntries.dropFirst(3))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Period picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(spacing: 16) {
                        // Podium
                        PodiumView(topThree: topThree)
                            .padding(.top, 8)

                        // Remaining ranked rows
                        VStack(spacing: 8) {
                            ForEach(remainingEntries) { entry in
                                LeaderboardRow(entry: entry)
                            }
                        }
                        .padding(.horizontal)

                        // Add Friends button
                        Button {
                            // TODO: add friends action
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
//            .navigationTitle("Leaderboard")
        }
    }
}

// MARK: - Podium

private struct PodiumView: View {
    let topThree: [LeaderboardEntry]

    // Order: 2nd, 1st, 3rd
    private var podiumOrder: [LeaderboardEntry] {
        guard topThree.count == 3 else { return topThree }
        return [topThree[1], topThree[0], topThree[2]]
    }

    private func podiumHeight(for rank: Int) -> CGFloat {
        switch rank {
        case 1: return 90
        case 2: return 60
        case 3: return 45
        default: return 45
        }
    }

    private func avatarSize(for rank: Int) -> CGFloat {
        rank == 1 ? 64 : 50
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(podiumOrder) { entry in
                VStack(spacing: 6) {
                    // Crown for 1st
                    if entry.rank == 1 {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                            .font(.title3)
                    }

                    // Avatar
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

                    // Podium block
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
            }
        }
        .padding(.horizontal)
    }

    private func avatarColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
}

// MARK: - Row

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("\(entry.rank)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // Avatar
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
    }
}

// MARK: - Preview

#Preview {
    LeaderboardScreen()
}
