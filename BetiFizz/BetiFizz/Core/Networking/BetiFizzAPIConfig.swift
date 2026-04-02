//
//  BetiFizzAPIConfig.swift
//  BetiFizz
//

import Foundation

enum BetiFizzAPIConfig {
    /// Token is set in `FootballDataToken.swift` (see comments in that file).
    static var footballDataOrgKey: String {
        FootballDataToken.value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
