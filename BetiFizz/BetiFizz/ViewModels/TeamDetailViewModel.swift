//
//  TeamDetailViewModel.swift
//  BetiFizz
//

import Combine
import CoreData
import Foundation

struct BetiFizzSquadPlayer: Identifiable, Equatable {
    let id: String
    let name: String
    let position: String?
    let shirtNumber: Int?
}

@MainActor
final class TeamDetailViewModel: ObservableObject {
    @Published var team: Team?
    @Published var squad: [BetiFizzSquadPlayer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var stateVersion = 0

    private let service = TeamsService.shared

    func load(teamId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if let cached = TeamDetailJSONCache.load(teamId: teamId) {
            team = cached.team
            squad = cached.squad.map {
                BetiFizzSquadPlayer(
                    id: $0.id,
                    name: $0.name,
                    position: $0.position,
                    shirtNumber: $0.shirtNumber
                )
            }
            return
        }

        do {
            let dto = try await service.fetchTeamDetail(id: teamId)
            let mappedTeam = Team(
                id: "\(dto.id)",
                name: dto.name,
                fullName: dto.name,
                abbreviation: dto.tla,
                city: dto.area.name,
                division: nil,
                logoURL: dto.crest
            )
            let mappedSquad = (dto.squad ?? [])
                .filter { ($0.role ?? "PLAYER") == "PLAYER" }
                .map {
                    BetiFizzSquadPlayer(
                        id: "\($0.id)",
                        name: $0.name,
                        position: $0.position,
                        shirtNumber: $0.shirtNumber
                    )
                }
                .sorted { ($0.shirtNumber ?? 999) < ($1.shirtNumber ?? 999) }
            team = mappedTeam
            squad = mappedSquad
            TeamDetailJSONCache.save(teamId: teamId, team: mappedTeam, squad: mappedSquad)
        } catch {
            errorMessage = error.localizedDescription
            team = nil
            squad = []
        }
    }

    func isFavorite(context: NSManagedObjectContext, teamId: String) -> Bool {
        FavoriteTeamRepository.isFavorite(teamId: teamId, in: context)
    }

    func toggleFavorite(context: NSManagedObjectContext) {
        guard let t = team else { return }
        FavoriteTeamRepository.toggle(teamId: t.id, name: t.name, crestURL: t.logoURL, in: context)
        stateVersion += 1
    }
}
