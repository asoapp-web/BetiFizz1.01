//
//  BetiFizzMatchFetchRange.swift
//  BetiFizz
//
//  football-data.org free tier: period must not exceed 10 days (inclusive).
//

import Foundation

struct BetiFizzMatchFetchRange: Equatable, Codable {
    enum Mode: String, Codable {
        case rollingNextDays
        case customRange
        case singleDay
    }

    /// How to build the API window.
    var mode: Mode
    /// For `.rollingNextDays`: 1…10, counted from local **today**.
    var rollingDays: Int
    /// Local start-of-day (`timeIntervalSince1970`) for `.customRange` (from) and `.singleDay`.
    var rangeStart: TimeInterval?
    /// Local start-of-day for `.customRange` (to). Ignored for other modes.
    var rangeEnd: TimeInterval?

    static let `default` = BetiFizzMatchFetchRange(
        mode: .rollingNextDays,
        rollingDays: 10,
        rangeStart: nil,
        rangeEnd: nil
    )

    static let apiMaxInclusiveDays = 10

    static func inclusiveDayCount(from start: Date, to end: Date, cal: Calendar = .current) -> Int {
        let a = cal.startOfDay(for: start)
        let b = cal.startOfDay(for: end)
        let dc = cal.dateComponents([.day], from: a, to: b)
        return (dc.day ?? 0) + 1
    }

    /// Resolved inclusive local start/end days for the API (`dateFrom` / `dateTo`).
    func resolvedLocalDayBounds(cal: Calendar = .current) -> (from: Date, to: Date)? {
        let today0 = cal.startOfDay(for: Date())
        switch mode {
        case .rollingNextDays:
            let n = min(Self.apiMaxInclusiveDays, max(1, rollingDays))
            guard let end = cal.date(byAdding: .day, value: n - 1, to: today0) else { return nil }
            return (today0, end)
        case .singleDay:
            guard let ts = rangeStart else { return nil }
            let d = cal.startOfDay(for: Date(timeIntervalSince1970: ts))
            return (d, d)
        case .customRange:
            guard let ts = rangeStart, let te = rangeEnd else { return nil }
            var f = cal.startOfDay(for: Date(timeIntervalSince1970: ts))
            var t = cal.startOfDay(for: Date(timeIntervalSince1970: te))
            if f > t { swap(&f, &t) }
            guard Self.inclusiveDayCount(from: f, to: t, cal: cal) <= Self.apiMaxInclusiveDays else { return nil }
            return (f, t)
        }
    }

    func isValid(cal: Calendar = .current) -> Bool {
        guard let (f, t) = resolvedLocalDayBounds(cal: cal) else { return false }
        return Self.inclusiveDayCount(from: f, to: t, cal: cal) <= Self.apiMaxInclusiveDays && f <= t
    }
}

enum BetiFizzMatchFetchRangeStore {
    private static let key = "BetiFizz.matchFetchRange.v1"

    static func load() -> BetiFizzMatchFetchRange {
        guard let data = UserDefaults.standard.data(forKey: key),
              let r = try? JSONDecoder().decode(BetiFizzMatchFetchRange.self, from: data)
        else { return .default }
        return r.isValid() ? r : .default
    }

    static func save(_ range: BetiFizzMatchFetchRange) {
        guard range.isValid(),
              let data = try? JSONEncoder().encode(range)
        else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
