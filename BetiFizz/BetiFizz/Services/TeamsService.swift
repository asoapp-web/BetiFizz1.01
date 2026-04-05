//
//  TeamsService.swift
//  BetiFizz
//

import Foundation

final class TeamsService {
    static let shared = TeamsService()
    private let api = FootballDataOrgClient.shared

    /// Top European leagues commonly available on free football-data tier.
    private let topLeagueIds = [2021, 2014, 2019, 2002]

    private init() {}

    func fetchTeams() async throws -> [BetiFizzTeam] {
        let response: FootballDataOrgCompetitionsResponse = try await api.fetch(
            endpoint: "competitions?plan=TIER_ONE",
            as: FootballDataOrgCompetitionsResponse.self
        )
        var all: [BetiFizzTeam] = []
        for comp in response.competitions where topLeagueIds.contains(comp.id) {
            do {
                let teamsResp: FootballDataOrgTeamsResponse = try await api.fetch(
                    endpoint: "competitions/\(comp.id)/teams",
                    as: FootballDataOrgTeamsResponse.self
                )
                for t in teamsResp.teams {
                    all.append(BetiFizzTeam(
                        id: "\(t.id)",
                        name: t.name,
                        fullName: t.name,
                        abbreviation: t.tla,
                        city: t.area.name,
                        division: comp.name,
                        logoURL: t.crest
                    ))
                }
            } catch {
                continue
            }
        }
        return all
    }

    func fetchTeamDetail(id: String) async throws -> FootballDataOrgTeamDetail {
        try await api.fetch(endpoint: "teams/\(id)", as: FootballDataOrgTeamDetail.self)
    }
}
