//
//  BetiFizzKnownCompetitions.swift
//  BetiFizz
//
//  Tier-one competition ids from football-data.org (free plan).
//  Used so the league picker is never empty when the day’s match list is empty.
//

import Foundation

enum BetiFizzKnownCompetitions {
    /// `id` must match `competition.id` from match payloads (stringified).
    static let displayLeagues: [BetiFizzLeagueOption] = [
        BetiFizzLeagueOption(id: "2001", name: "UEFA Champions League", code: "CL"),
        BetiFizzLeagueOption(id: "2021", name: "Premier League", code: "PL"),
        BetiFizzLeagueOption(id: "2014", name: "Primera Division", code: "PD"),
        BetiFizzLeagueOption(id: "2002", name: "Bundesliga", code: "BL1"),
        BetiFizzLeagueOption(id: "2019", name: "Serie A", code: "SA"),
        BetiFizzLeagueOption(id: "2015", name: "Ligue 1", code: "FL1"),
        BetiFizzLeagueOption(id: "2016", name: "Championship", code: "ELC"),
        BetiFizzLeagueOption(id: "2003", name: "Eredivisie", code: "DED"),
        BetiFizzLeagueOption(id: "2017", name: "Primeira Liga", code: "PPL"),
        BetiFizzLeagueOption(id: "2013", name: "Campeonato Brasileiro Série A", code: "BSA"),
        BetiFizzLeagueOption(id: "2018", name: "European Championship", code: "EC"),
        BetiFizzLeagueOption(id: "2000", name: "FIFA World Cup", code: "WC"),
    ]
}
