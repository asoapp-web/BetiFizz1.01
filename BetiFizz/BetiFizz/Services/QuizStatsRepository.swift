//
//  QuizStatsRepository.swift
//  BetiFizz
//

import CoreData
import Foundation

extension Notification.Name {
    static let betiFizzQuizStatsDidChange = Notification.Name("betiFizzQuizStatsDidChange")
}

struct QuizStatsSnapshot: Equatable {
    var attempted: Int32
    var correct: Int32
    var bestStreak: Int32
    var currentStreak: Int32
    var lastPlayedAt: Date?

    var accuracyText: String {
        guard attempted > 0 else { return "—" }
        let pct = Double(correct) / Double(attempted) * 100
        return String(format: "%.0f%%", pct)
    }
}

enum QuizStatsRepository {
    static func bootstrapIfNeeded(context: NSManagedObjectContext) {
        context.performAndWait {
            let request = QuizStats.fetchRequest()
            request.fetchLimit = 1
            let count = (try? context.count(for: request)) ?? 0
            guard count == 0 else { return }
            let row = QuizStats(context: context)
            row.attempted = 0
            row.correct = 0
            row.bestStreak = 0
            row.currentStreak = 0
            try? context.save()
        }
    }

    static func snapshot(context: NSManagedObjectContext) -> QuizStatsSnapshot {
        var result = QuizStatsSnapshot(attempted: 0, correct: 0, bestStreak: 0, currentStreak: 0, lastPlayedAt: nil)
        context.performAndWait {
            let request = QuizStats.fetchRequest()
            request.fetchLimit = 1
            guard let row = try? context.fetch(request).first else { return }
            result = QuizStatsSnapshot(
                attempted: row.attempted,
                correct: row.correct,
                bestStreak: row.bestStreak,
                currentStreak: row.currentStreak,
                lastPlayedAt: row.lastPlayedAt
            )
        }
        return result
    }

    static func recordAnswer(isCorrect: Bool, context: NSManagedObjectContext) {
        context.performAndWait {
            let request = QuizStats.fetchRequest()
            request.fetchLimit = 1
            guard let row = try? context.fetch(request).first else { return }
            row.attempted += 1
            if isCorrect {
                row.correct += 1
                row.currentStreak += 1
                if row.currentStreak > row.bestStreak {
                    row.bestStreak = row.currentStreak
                }
            } else {
                row.currentStreak = 0
            }
            row.lastPlayedAt = Date()
            try? context.save()
            Self.postStatsChanged()
        }
    }

    static func resetAll(context: NSManagedObjectContext) {
        context.performAndWait {
            let request = QuizStats.fetchRequest()
            request.fetchLimit = 1
            guard let row = try? context.fetch(request).first else { return }
            row.attempted = 0
            row.correct = 0
            row.bestStreak = 0
            row.currentStreak = 0
            row.lastPlayedAt = nil
            try? context.save()
            Self.postStatsChanged()
        }
    }

    private static func postStatsChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .betiFizzQuizStatsDidChange, object: nil)
        }
    }
}
