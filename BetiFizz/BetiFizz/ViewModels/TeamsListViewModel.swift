//
//  TeamsListViewModel.swift
//  BetiFizz
//

import Combine
import CoreData
import Foundation

@MainActor
final class TeamsListViewModel: ObservableObject {
    static let shared = TeamsListViewModel()

    @Published var teams: [Team] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var favoritesVersion = 0

    private let service = TeamsService.shared
    private var hasLoadedOnce = false
    private let cacheTTL: TimeInterval = 30 * 24 * 60 * 60

    private struct CachePayload: Codable {
        let teams: [Team]
        let cachedAt: Date
    }

    var filteredTeams: [Team] {
        guard !searchText.isEmpty else { return teams }
        return teams.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.fullName.localizedCaseInsensitiveContains(searchText)
                || ($0.city?.localizedCaseInsensitiveContains(searchText) ?? false)
                || ($0.division?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var teamsByDivision: [(division: String, teams: [Team])] {
        let grouped = Dictionary(grouping: filteredTeams) { $0.division ?? "Other" }
        return grouped.keys.sorted().compactMap { div in
            guard let t = grouped[div], !t.isEmpty else { return nil }
            return (division: div, teams: t.sorted { $0.name < $1.name })
        }
    }

    func loadTeams() async {
        if hasLoadedOnce, !teams.isEmpty { return }

        let ud = UserDefaults.standard
        let key = BetiFizzUserDefaultsKeys.teamsCache

        if !hasLoadedOnce || teams.isEmpty, let data = ud.data(forKey: key) {
            if let payload = try? JSONDecoder().decode(CachePayload.self, from: data),
               payload.cachedAt.addingTimeInterval(cacheTTL) > Date() {
                teams = payload.teams
                hasLoadedOnce = true
                isLoading = false
                return
            }
        }

        isLoading = true
        errorMessage = nil
        do {
            let bf = try await service.fetchTeams()
            teams = bf.map { $0.toTeam() }
            hasLoadedOnce = true
            if let data = try? JSONEncoder().encode(CachePayload(teams: teams, cachedAt: Date())) {
                ud.set(data, forKey: key)
            }
        } catch {
            errorMessage = error.localizedDescription
            teams = []
        }
        isLoading = false
    }

    func isFavorite(teamId: String, context: NSManagedObjectContext) -> Bool {
        FavoriteTeamRepository.isFavorite(teamId: teamId, in: context)
    }

    func toggleFavorite(team: Team, context: NSManagedObjectContext) {
        FavoriteTeamRepository.toggle(teamId: team.id, name: team.name, crestURL: team.logoURL, in: context)
        favoritesVersion += 1
    }
}
