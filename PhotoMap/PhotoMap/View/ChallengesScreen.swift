import SwiftUI

// MARK: - Display Model

struct Challenge: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let difficulty: Difficulty
    let current: Int
    let goal: Int
    let unit: String
    let typeId: Int
    let timeRemaining: String
    let isCompleted: Bool

    enum Difficulty: Int {
        case easy = 1
        case medium = 2
        case hard = 3

        var label: String {
            switch self {
            case .easy:   return "Easy"
            case .medium: return "Medium"
            case .hard:   return "Hard"
            }
        }

        var color: Color {
            switch self {
            case .easy:   return .green
            case .medium: return .orange
            case .hard:   return .red
            }
        }
    }

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(current) / Double(goal), 1.0)
    }

    /// Convert a Supabase joined row into a display model.
    init(from userChallenge: UserChallengeWithDetails) {
        let row = userChallenge.challenges
        id = userChallenge.id
        title = row.title
        description = row.description
        difficulty = Difficulty(rawValue: row.difficulty) ?? .easy
        current = userChallenge.progress
        goal = row.goal
        unit = row.unit
        typeId = row.typeId
        isCompleted = userChallenge.isCompleted
        timeRemaining = userChallenge.isCompleted
            ? "Completed"
            : userChallenge.expiresAt.timeRemainingString
    }
}

// MARK: - Date Helper

private extension Date {
    var timeRemainingString: String {
        let now = Date()
        guard self > now else { return "Expired" }
        let components = Calendar.current.dateComponents([.day, .hour], from: now, to: self)
        if let days = components.day, days > 0 {
            return "\(days) Day\(days == 1 ? "" : "s") Left"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) Hour\(hours == 1 ? "" : "s") Left"
        }
        return "Expiring Soon"
    }
}

// MARK: - Screen

struct ChallengesScreen: View {
    @StateObject private var viewModel = ChallengesViewModel()
    @State private var selectedFilter: Filter = .active

    enum Filter: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
    }

    private var filteredChallenges: [Challenge] {
        selectedFilter == .active ? viewModel.activeChallenges : viewModel.completedChallenges
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(Filter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .accessibilityLabel("Challenge filter")
                .accessibilityHint("Select to show active or completed challenges")

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading Challenges...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    ContentUnavailableView(
                        "Couldn't Load Challenges",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                    Spacer()
                } else if filteredChallenges.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        selectedFilter == .active ? "No Active Challenges" : "No Completed Challenges",
                        systemImage: "flag.checkered",
                        description: Text(selectedFilter == .active
                            ? "Check back soon for new challenges."
                            : "Complete challenges to see them here.")
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredChallenges) { challenge in
                                ChallengeCard(challenge: challenge)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Challenges")
            .task {
                await viewModel.load()
            }
        }
    }
}

// MARK: - Card

private struct ChallengeCard: View {
    let challenge: Challenge

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.headline)
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Difficulty badge
                Text(challenge.difficulty.label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(challenge.difficulty.color.opacity(0.15))
                    .foregroundStyle(challenge.difficulty.color)
                    .clipShape(Capsule())
                    .accessibilityLabel("\(challenge.difficulty.label) difficulty")
            }

            // Progress bar
            ProgressView(value: challenge.progress)
                .tint(challenge.isCompleted ? .gray : .green)
                .accessibilityLabel("Progress")
                .accessibilityValue("\(Int(challenge.progress * 100)) percent complete, \(challenge.current) of \(challenge.goal) \(challenge.unit)")

            // Footer row
            HStack {
                Text("\(challenge.current)/\(challenge.goal) \(challenge.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(challenge.timeRemaining)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.title), \(challenge.difficulty.label) difficulty, \(challenge.current) of \(challenge.goal) \(challenge.unit), \(challenge.timeRemaining)")
    }
}

// MARK: - Preview

#Preview {
    ChallengesScreen()
}
