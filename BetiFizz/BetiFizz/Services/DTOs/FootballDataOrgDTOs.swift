//
//  FootballDataOrgDTOs.swift
//  BetiFizz
//

import Foundation

struct FootballDataOrgCompetitionsResponse: Codable {
    let competitions: [FootballDataOrgCompetition]
}

struct FootballDataOrgCompetition: Codable {
    let id: Int
    let name: String
    let code: String?
    let type: String
    let emblem: String?
    let area: FootballDataOrgArea
    let currentSeason: FootballDataOrgSeason?
}

struct FootballDataOrgArea: Codable {
    let id: Int
    let name: String
    let code: String?
}

struct FootballDataOrgSeason: Codable {
    let id: Int
    let startDate: String
    let endDate: String
    let currentMatchday: Int?
}

struct FootballDataOrgMatchesResponse: Codable {
    let matches: [FootballDataOrgMatch]
}

struct FootballDataOrgMatch: Codable {
    let id: Int
    let utcDate: String
    let status: String
    let minute: Int?
    let injuryTime: Int?
    let matchday: Int?
    let stage: String?
    let homeTeam: FootballDataOrgTeamDTO
    let awayTeam: FootballDataOrgTeamDTO
    let score: FootballDataOrgScore?
    let competition: FootballDataOrgCompetitionInfo
    let venue: String?
    let attendance: Int?
}

struct FootballDataOrgTeamDTO: Codable {
    let id: Int
    let name: String
    let shortName: String?
    let crest: String?
}

struct FootballDataOrgScore: Codable {
    let winner: String?
    let fullTime: FootballDataOrgScoreDetail?
}

struct FootballDataOrgScoreDetail: Codable {
    let home: Int?
    let away: Int?
}

struct FootballDataOrgCompetitionInfo: Codable {
    let id: Int
    let name: String
    let code: String?
}

struct FootballDataOrgTeamsResponse: Codable {
    let teams: [FootballDataOrgTeamDetail]
}

struct FootballDataOrgTeamDetail: Codable {
    let id: Int
    let name: String
    let shortName: String?
    let tla: String?
    let crest: String?
    let address: String?
    let website: String?
    let founded: Int?
    let clubColors: String?
    let venue: String?
    let area: FootballDataOrgArea
    let squad: [FootballDataOrgPlayer]?
}

struct FootballDataOrgPlayer: Codable {
    let id: Int
    let name: String
    let position: String?
    let dateOfBirth: String?
    let nationality: String?
    let shirtNumber: Int?
    let role: String?
}
