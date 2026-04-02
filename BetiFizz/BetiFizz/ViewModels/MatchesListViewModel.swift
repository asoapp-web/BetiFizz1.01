//
//  MatchesListViewModel.swift
//  BetiFizz
//

import Combine
import CoreData
import Foundation

enum BetiFizzMatchDateFilter: String, CaseIterable {
    case all
    case today

    var shortTitle: String {
        switch self {
        case .all:   return "All"
        case .today: return "Today"
        }
    }
}

struct BetiFizzLeagueOption: Identifiable, Equatable {
    let id: String
    let name: String
    let code: String?
    var flag: String { BetiFizzMatch.flag(for: code) }
}

@MainActor
final class MatchesListViewModel: ObservableObject {
    static let shared = MatchesListViewModel()

    @Published var matches: [BetiFizzMatch] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var matchFilter: BetiFizzMatchDateFilter = .all
    @Published var selectedLeagueIds: Set<String> = []
    @Published var fetchRange: BetiFizzMatchFetchRange
    @Published var stateVersion = 0

    private let fixtures = FixturesService.shared

    private struct CachePayload: Codable {
        let matches: [BetiFizzMatch]
        let fromYmd: String
        let toYmd: String
        let leagueKey: String
    }

    private init() {
        fetchRange = BetiFizzMatchFetchRangeStore.load()
    }

    static func leagueCacheKey(_ ids: Set<String>) -> String {
        ids.isEmpty ? "all" : ids.sorted().joined(separator: ",")
    }

    private static func ymd(_ date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// Short label for the date-range chip (e.g. `10d`, `Mar 24–26`).
    var fetchRangeShortLabel: String {
        guard let (f, t) = fetchRange.resolvedLocalDayBounds() else { return "Dates" }
        let cal = Calendar.current
        if cal.isDate(f, inSameDayAs: t) {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .none
            return fmt.string(from: f)
        }
        if fetchRange.mode == .rollingNextDays {
            return "\(min(10, max(1, fetchRange.rollingDays)))d"
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: f))–\(fmt.string(from: t))"
    }

    var availableLeagues: [BetiFizzLeagueOption] {
        var byId: [String: BetiFizzLeagueOption] = Dictionary(
            uniqueKeysWithValues: BetiFizzKnownCompetitions.displayLeagues.map { ($0.id, $0) }
        )
        for m in matches {
            let code = m.competitionCode ?? byId[m.leagueId]?.code
            byId[m.leagueId] = BetiFizzLeagueOption(id: m.leagueId, name: m.leagueName, code: code)
        }
        return byId.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var liveMatches: [BetiFizzMatch] {
        matches.filter { $0.isLive }.sorted { $0.date < $1.date }
    }

    var filteredMatches: [BetiFizzMatch] {
        let cal = Calendar.current
        let byDate: [BetiFizzMatch]
        switch matchFilter {
        case .all:
            byDate = matches
        case .today:
            byDate = matches.filter { cal.isDateInToday($0.date) }
        }

        let leagueFiltered: [BetiFizzMatch]
        if selectedLeagueIds.isEmpty {
            leagueFiltered = byDate
        } else {
            leagueFiltered = byDate.filter { selectedLeagueIds.contains($0.leagueId) }
        }

        return leagueFiltered.sorted { a, b in
            if a.isLive != b.isLive { return a.isLive && !b.isLive }
            return a.date < b.date
        }
    }

    func loadMatches(force: Bool = false) async {
        guard let (fromD, toD) = fetchRange.resolvedLocalDayBounds() else {
            errorMessage = BetiFizzAPIError.dateRangeExceedsApiLimit.localizedDescription
            return
        }

        let fromY = Self.ymd(fromD)
        let toY = Self.ymd(toD)
        let lKey = Self.leagueCacheKey(selectedLeagueIds)
        let compIds = Array(selectedLeagueIds).sorted()
        let ud = UserDefaults.standard
        let key = BetiFizzUserDefaultsKeys.matchesCache

        if !force,
           let data = ud.data(forKey: key),
           let payload = try? JSONDecoder().decode(CachePayload.self, from: data),
           payload.fromYmd == fromY,
           payload.toYmd == toY,
           payload.leagueKey == lKey {
            BetiFizzLogger.info("Matches from cache (\(payload.matches.count)), \(fromY)…\(toY), leagues=\(lKey)")
            matches = payload.matches
            isLoading = false
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await fixtures.fetchMatches(
                localFrom: fromD,
                localTo: toD,
                competitionIds: compIds
            )
            BetiFizzLogger.info("Matches received: \(fetched.count) (\(fromY)…\(toY), leagues=\(lKey))")
            matches = fetched
            let payload = CachePayload(matches: fetched, fromYmd: fromY, toYmd: toY, leagueKey: lKey)
            if let encoded = try? JSONEncoder().encode(payload) {
                ud.set(encoded, forKey: key)
            }
        } catch {
            if Self.isCancellation(error) {
                BetiFizzLogger.info("loadMatches cancelled — keeping existing list")
            } else {
                BetiFizzLogger.logError(error)
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func refresh() async {
        await loadMatches(force: true)
    }

    func applyLeagueSelection(_ ids: Set<String>) async {
        selectedLeagueIds = ids
        await loadMatches(force: true)
    }

    func applyFetchRange(_ range: BetiFizzMatchFetchRange) async {
        guard range.isValid() else {
            errorMessage = BetiFizzAPIError.dateRangeExceedsApiLimit.localizedDescription
            return
        }
        fetchRange = range
        BetiFizzMatchFetchRangeStore.save(range)
        await loadMatches(force: true)
    }

    func pollLiveMatchesWhileVisible() async {
        while !Task.isCancelled {
            let liveIds = matches.filter(\.isLive).map(\.id)
            if liveIds.isEmpty {
                try? await Task.sleep(nanoseconds: 90_000_000_000)
                continue
            }
            for id in liveIds where !Task.isCancelled {
                do {
                    if let m = try await fixtures.fetchMatch(id: id),
                       let idx = matches.firstIndex(where: { $0.id == id }) {
                        matches[idx] = m
                    }
                } catch {
                    if !Self.isCancellation(error) { }
                }
            }
            stateVersion += 1
            try? await Task.sleep(nanoseconds: 45_000_000_000)
        }
    }

    func isFavorite(teamId: String, context: NSManagedObjectContext) -> Bool {
        FavoriteTeamRepository.isFavorite(teamId: teamId, in: context)
    }

    func toggleFavorite(teamId: String, name: String, crest: String?, context: NSManagedObjectContext) {
        FavoriteTeamRepository.toggle(teamId: teamId, name: name, crestURL: crest, in: context)
        stateVersion += 1
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let ns = error as NSError
        return ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled
    }
}
