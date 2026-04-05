//
//  Team.swift
//  BetiFizz
//

import Foundation

struct Team: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let fullName: String
    let abbreviation: String?
    let city: String?
    let division: String?
    let logoURL: String?
}

struct BetiFizzTeam: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let fullName: String
    let abbreviation: String?
    let city: String?
    let division: String?
    let logoURL: String?

    func toTeam() -> Team {
        Team(
            id: id,
            name: name,
            fullName: fullName,
            abbreviation: abbreviation,
            city: city,
            division: division,
            logoURL: logoURL
        )
    }
}
