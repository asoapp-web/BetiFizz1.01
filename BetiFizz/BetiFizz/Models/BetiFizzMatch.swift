//
//  BetiFizzMatch.swift
//  BetiFizz
//

import Foundation

struct BetiFizzMatch: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let leagueId: String
    let leagueName: String
    /// Competition code from football-data.org (PL, BL1, SA, …) for flag emoji.
    let competitionCode: String?
    let season: Int
    let homeTeamId: String
    let awayTeamId: String
    let homeTeamName: String
    let awayTeamName: String
    let homeTeamLogoURL: String?
    let awayTeamLogoURL: String?
    let date: Date
    let status: Status
    let period: Int
    let time: String?
    let homeScore: Int?
    let awayScore: Int?
    let postseason: Bool

    enum Status: String, Codable {
        case scheduled
        case live
        case halftime
        case final
        case postponed

        var isLive: Bool {
            switch self {
            case .live, .halftime: return true
            default: return false
            }
        }
    }

    var isLive: Bool { status.isLive }
    var isFinished: Bool { status == .final }
    var isUpcoming: Bool { status == .scheduled && date > Date() }

    var leagueFlag: String { BetiFizzMatch.flag(for: competitionCode) }

    static func flag(for code: String?) -> String {
        switch code {
        case "PL":  return "🏴󠁧󠁢󠁥󠁮󠁧󠁿"   // Premier League
        case "ELC": return "🏴󠁧󠁢󠁥󠁮󠁧󠁿"   // Championship
        case "BL1": return "🇩🇪"   // Bundesliga
        case "SA":  return "🇮🇹"   // Serie A
        case "PD":  return "🇪🇸"   // Primera Division
        case "FL1": return "🇫🇷"   // Ligue 1
        case "PPL": return "🇵🇹"   // Primeira Liga
        case "DED": return "🇳🇱"   // Eredivisie
        case "BSA": return "🇧🇷"   // Série A Brasil
        case "CL":  return "🇪🇺"   // Champions League
        case "EC":  return "🇪🇺"   // European Championship
        case "WC":  return "🌍"    // World Cup
        case "CLI": return "🌎"    // Copa Libertadores
        default:    return "⚽️"
        }
    }
}

// MARK: - DTO mapping

extension FootballDataOrgMatch {
    func toBetiFizzMatch() -> BetiFizzMatch {
        let parsedDate: Date = {
            let utc = TimeZone(identifier: "UTC")!
            let f1 = ISO8601DateFormatter()
            f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            f1.timeZone = utc
            if let d = f1.date(from: utcDate) { return d }
            let f2 = ISO8601DateFormatter()
            f2.formatOptions = [.withInternetDateTime]
            f2.timeZone = utc
            return f2.date(from: utcDate) ?? Date()
        }()

        let matchStatus: BetiFizzMatch.Status = {
            switch status {
            case "SCHEDULED":           return .scheduled
            case "LIVE", "IN_PLAY":     return .live
            case "PAUSED":              return .halftime
            case "FINISHED":            return .final
            case "POSTPONED",
                 "CANCELLED":           return .postponed
            default:                    return .scheduled
            }
        }()

        let timeLabel: String? = {
            if status == "LIVE" || status == "IN_PLAY" {
                if let m = minute, m > 0 { return "\(m)'" }
                return "Live"
            }
            if status == "PAUSED" { return "HT" }
            return nil
        }()

        let year = Calendar.current.component(.year, from: parsedDate)

        return BetiFizzMatch(
            id: "\(id)",
            leagueId: "\(competition.id)",
            leagueName: competition.name,
            competitionCode: competition.code,
            season: year,
            homeTeamId: "\(homeTeam.id)",
            awayTeamId: "\(awayTeam.id)",
            homeTeamName: homeTeam.name,
            awayTeamName: awayTeam.name,
            homeTeamLogoURL: homeTeam.crest,
            awayTeamLogoURL: awayTeam.crest,
            date: parsedDate,
            status: matchStatus,
            period: minute ?? 0,
            time: timeLabel,
            homeScore: score?.fullTime?.home,
            awayScore: score?.fullTime?.away,
            postseason: false
        )
    }
}

// MARK: - Favorites spotlight

extension BetiFizzMatch {
    /// Best match to show for a favorite team: live → next kickoff → most recent finished.
    static func spotlight(forTeamId teamId: String, in matches: [BetiFizzMatch]) -> BetiFizzMatch? {
        let involved = matches.filter { $0.homeTeamId == teamId || $0.awayTeamId == teamId }
        guard !involved.isEmpty else { return nil }
        if let live = involved.filter(\.isLive).min(by: { $0.date < $1.date }) { return live }
        let now = Date()
        let upcoming = involved
            .filter { $0.status == .scheduled && $0.date >= now }
            .sorted { $0.date < $1.date }
        if let next = upcoming.first { return next }
        return involved.filter(\.isFinished).max { $0.date < $1.date }
    }

    /// Compact line for the Favorites list (uses loaded fixtures).
    func favoritesSpotlightLine() -> String {
        if isLive {
            let hs = homeScore.map(String.init) ?? "–"
            let aw = awayScore.map(String.init) ?? "–"
            return "\(leagueFlag) LIVE · \(homeTeamName) \(hs)-\(aw) \(awayTeamName)"
        }
        if isFinished {
            let hs = homeScore.map(String.init) ?? "0"
            let aw = awayScore.map(String.init) ?? "0"
            return "\(leagueFlag) FT \(homeTeamName) \(hs)-\(aw) \(awayTeamName)"
        }
        return "\(leagueFlag) \(homeTeamName) vs \(awayTeamName) · \(date.betiFizzFormattedMatchLine())"
    }
}
