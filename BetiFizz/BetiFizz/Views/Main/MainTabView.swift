//
//  MainTabView.swift
//  BetiFizz
//

import CoreData
import SwiftUI

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            MatchesHomeView()
                .tabItem { Label("Matches", systemImage: "sportscourt.fill") }

            NotesTabView()
                .tabItem { Label("Notes", systemImage: "note.text") }

            InteractiveTabView()
                .tabItem { Label("Interactive", systemImage: "gamecontroller.fill") }

            FavoritesListView()
                .tabItem { Label("Favorites", systemImage: "star.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(BetiFizzTheme.primaryGreen)
        .onAppear {
            QuizStatsRepository.bootstrapIfNeeded(context: viewContext)
        }
    }
}

// MARK: - Favorites tab

private struct FavoritesListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteTeam.addedAt, ascending: false)],
        animation: .default
    )
    private var teams: FetchedResults<FavoriteTeam>

    @StateObject private var matchesVM = MatchesListViewModel.shared
    @StateObject private var teamsVM = TeamsListViewModel.shared
    @State private var path: [MatchesRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LiquidGlassScreenBackground()
                ScrollView {
                    Group {
                        if teams.isEmpty {
                            emptyPlaceholder
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(teams), id: \.objectID) { team in
                                    let teamId = team.remoteId ?? ""
                                    FavoriteTeamGlassCard(
                                        name: team.name ?? "Team",
                                        crestURL: team.crestURL,
                                        teamId: teamId,
                                        spotlight: BetiFizzMatch.spotlight(forTeamId: teamId, in: matchesVM.matches),
                                        fallbackSubtitle: favoriteFallbackSubtitle(teamId: teamId)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .betiFizzNavigationChrome()
            .navigationDestination(for: MatchesRoute.self) { route in
                switch route {
                case .match(let m):
                    MatchDetailView(match: m, path: $path)
                case .team(let id):
                    TeamDetailView(teamId: id)
                }
            }
        }
        .task {
            await matchesVM.loadMatches()
            await teamsVM.loadTeams()
        }
    }

    private func favoriteFallbackSubtitle(teamId: String) -> String {
        if let t = teamsVM.teams.first(where: { $0.id == teamId }) {
            let parts = [t.city, t.division].compactMap { $0 }.filter { !$0.isEmpty }
            if !parts.isEmpty { return parts.joined(separator: " · ") }
        }
        return "No fixtures for this team in your loaded range — open Matches to refresh."
    }

    private var emptyPlaceholder: some View {
        VStack {
            Spacer()
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(BetiFizzTheme.primaryGreen.opacity(0.85))
                    Text("No favourites yet")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(BetiFizzTheme.textPrimary)
                    Text("Star teams from the Matches tab to see them here.")
                        .font(.subheadline)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            Spacer()
        }
    }
}

// MARK: - Favorite team card

private struct FavoriteTeamGlassCard: View {
    let name: String
    let crestURL: String?
    let teamId: String
    let spotlight: BetiFizzMatch?
    let fallbackSubtitle: String

    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                NavigationLink(value: MatchesRoute.team(teamId)) {
                    HStack(spacing: 14) {
                        favoriteCrest(urlString: crestURL)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(name)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(BetiFizzTheme.textPrimary)
                                .multilineTextAlignment(.leading)
                            Text("Roster & details")
                                .font(.caption)
                                .foregroundStyle(BetiFizzTheme.primaryGreen.opacity(0.95))
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BetiFizzTheme.textSecondary.opacity(0.55))
                    }
                }
                .buttonStyle(.plain)

                if let m = spotlight {
                    NavigationLink(value: MatchesRoute.match(m)) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: m.isLive ? "dot.radiowaves.left.and.right" : "sportscourt.fill")
                                .font(.body)
                                .foregroundStyle(m.isLive ? Color.orange : BetiFizzTheme.primaryGreen)
                                .frame(width: 22)
                            Text(m.favoritesSpotlightLine())
                                .font(.caption.weight(.medium))
                                .foregroundStyle(BetiFizzTheme.textSecondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(BetiFizzTheme.textSecondary.opacity(0.45))
                        }
                        .padding(.top, 2)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.body)
                            .foregroundStyle(BetiFizzTheme.textSecondary.opacity(0.7))
                            .frame(width: 22)
                        Text(fallbackSubtitle)
                            .font(.caption)
                            .foregroundStyle(BetiFizzTheme.textSecondary.opacity(0.85))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func favoriteCrest(urlString: String?) -> some View {
        if let s = urlString, let u = URL(string: s) {
            AsyncImage(url: u) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                case .failure:
                    favoriteCrestPlaceholder
                case .empty:
                    favoriteCrestPlaceholder
                @unknown default:
                    favoriteCrestPlaceholder
                }
            }
            .frame(width: 48, height: 48)
        } else {
            favoriteCrestPlaceholder
                .frame(width: 48, height: 48)
        }
    }

    private var favoriteCrestPlaceholder: some View {
        ZStack {
            Circle()
                .fill(BetiFizzTheme.primaryGreen.opacity(0.15))
            Image(systemName: "shield.fill")
                .font(.title3)
                .foregroundStyle(BetiFizzTheme.primaryGreen)
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
