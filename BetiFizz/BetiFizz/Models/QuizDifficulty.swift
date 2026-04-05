//
//  QuizDifficulty.swift
//  BetiFizz
//

import Foundation

enum QuizDifficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    /// Length of a run; defines perceived difficulty.
    var questionCount: Int {
        switch self {
        case .easy: return 10
        case .medium: return 20
        case .hard: return 30
        }
    }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    /// Mixed into the daily seed so each difficulty gets a different fixed set for the same day.
    var dailySalt: String { "daily.\(rawValue)" }

    var practiceSalt: String { "practice.\(rawValue)" }
}
