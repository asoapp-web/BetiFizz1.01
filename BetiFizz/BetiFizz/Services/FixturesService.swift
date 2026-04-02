//
//  FixturesService.swift
//  BetiFizz
//

import Foundation

final class FixturesService {
    static let shared = FixturesService()
    private let api = FootballDataOrgClient.shared
    private init() {}

    private static func localYyyyMmDd(for date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// One request; **inclusive** local day span must be ≤ 10 (football-data.org free tier).
    func fetchMatches(
        localFrom fromDay: Date,
        localTo toDay: Date,
        competitionIds: [String] = []
    ) async throws -> [BetiFizzMatch] {
        let cal = Calendar.current
        let from0 = cal.startOfDay(for: fromDay)
        let to0 = cal.startOfDay(for: toDay)
        guard from0 <= to0 else {
            throw BetiFizzAPIError.dateRangeInvalid
        }
        let span = BetiFizzMatchFetchRange.inclusiveDayCount(from: from0, to: to0, cal: cal)
        guard span <= BetiFizzMatchFetchRange.apiMaxInclusiveDays else {
            throw BetiFizzAPIError.dateRangeExceedsApiLimit
        }

        let fromStr = Self.localYyyyMmDd(for: from0)
        let toStr = Self.localYyyyMmDd(for: to0)
        let tz = TimeZone.current.identifier
        let compsNote = competitionIds.isEmpty ? "all Tier One" : "competitions \(competitionIds.sorted().joined(separator: ","))"
        BetiFizzLogger.info("Matches query: \(fromStr) … \(toStr) (\(span)d inclusive, \(compsNote), \(tz))")

        var endpoint = "matches?dateFrom=\(fromStr)&dateTo=\(toStr)"
        if !competitionIds.isEmpty {
            endpoint += "&competitions=\(competitionIds.sorted().joined(separator: ","))"
        }

        let response: FootballDataOrgMatchesResponse = try await api.fetch(endpoint: endpoint, as: FootballDataOrgMatchesResponse.self)

        let mapped = response.matches.map { $0.toBetiFizzMatch() }
        guard let rangeEndExclusive = cal.date(byAdding: .day, value: 1, to: to0) else {
            return mapped.sorted { $0.date < $1.date }
        }
        let filtered = mapped.filter { $0.date >= from0 && $0.date < rangeEndExclusive }
        return filtered.sorted { $0.date < $1.date }
    }

    func fetchMatch(id: String) async throws -> BetiFizzMatch? {
        let dto: FootballDataOrgMatch = try await api.fetch(endpoint: "matches/\(id)", as: FootballDataOrgMatch.self)
        return dto.toBetiFizzMatch()
    }
}
