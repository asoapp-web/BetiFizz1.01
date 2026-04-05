//
//  Date+BetiFizz.swift
//  BetiFizz
//

import Foundation

extension Date {
    private static let matchDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private static let shortDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    func betiFizzFormattedMatchLine() -> String {
        Self.matchDateFormatter.string(from: self)
    }

    func betiFizzTimeOnly() -> String {
        Self.timeOnly.string(from: self)
    }

    func betiFizzShortDay() -> String {
        Self.shortDay.string(from: self)
    }

    var betiFizzIsToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}
