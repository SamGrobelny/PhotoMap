import SwiftUI
internal import Auth
import Supabase

struct ProfileScreen: View {
    var onLogout: () -> Void

    @State private var profile: UserProfile?
    @State private var showSignOutAlert = false
    @State private var selectedTab: ContentTab = .photos

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
                    contentSection
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
            .task {
                await loadProfile()
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
                // Placeholder while loading
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 34)
            }

            if let createdAt = profile?.createdAt {
                Text("Member since \(createdAt.formatted(.dateTime.month(.wide).year()))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            statsRow
                .padding(.top, 4)
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

    private var statsRow: some View {
        HStack(spacing: 32) {
            StatView(value: photoCount,          label: "Photos")
            StatView(value: challengesCompleted, label: "Challenges")
            StatView(value: points,              label: "Points")
        }
    }

    // MARK: - Content Tabs

    private var contentSection: some View {
        VStack(spacing: 0) {
            Picker("Content", selection: $selectedTab) {
                ForEach(ContentTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            switch selectedTab {
            case .photos:
                emptyState(
                    icon: "photo.badge.plus",
                    title: "No Photos Yet",
                    subtitle: "Your pinned photos will appear here."
                )
            case .challenges:
                emptyState(
                    icon: "flag.checkered",
                    title: "No Active Challenges",
                    subtitle: "Head to the Challenges tab to get started."
                )
            case .completed:
                emptyState(
                    icon: "checkmark.seal",
                    title: "Nothing Completed Yet",
                    subtitle: "Completed challenges will show up here."
                )
            }
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Spacer(minLength: 60)
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 40)
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
            //screen still renders without profile data
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
