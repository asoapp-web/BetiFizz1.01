//
//  QuizBankProvider.swift
//  BetiFizz — bundled JSON only (no network)
//

import Foundation

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xdeadbeefcafe : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

enum QuizBankProvider {
    /// `quiz_questions.json` + any `quiz_bank_*.json` in the bundle.
    static func loadAllQuestions() throws -> [QuizQuestion] {
        var merged: [QuizQuestion] = []
        merged.append(contentsOf: try QuizQuestionsLoader.loadDefaultDeck())
        merged.append(contentsOf: try loadBundledBankShards())
        return dedupe(merged)
    }

    private static func loadBundledBankShards() throws -> [QuizQuestion] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else { return [] }
        var out: [QuizQuestion] = []
        for url in urls {
            let name = url.lastPathComponent
            guard name.hasPrefix("quiz_bank_"), name.hasSuffix(".json") else { continue }
            let data = try Data(contentsOf: url)
            out.append(contentsOf: try JSONDecoder().decode([QuizQuestion].self, from: data))
        }
        return out
    }

    private static func dedupe(_ items: [QuizQuestion]) -> [QuizQuestion] {
        var seen = Set<String>()
        var out: [QuizQuestion] = []
        for q in items {
            let key = q.question.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)
            out.append(q)
        }
        return out
    }

    private static func mixDaySeed(_ base: UInt64, salt: String, count: Int) -> UInt64 {
        var s = base ^ (UInt64(count) &* 0x9E37_79B9_7F4A_7C15)
        for b in salt.utf8 {
            s = s &* 1_099_511_628_211 &+ UInt64(b)
        }
        s ^= UInt64(salt.count &+ count) &* 0xC2B2_AE3D_27D4_EB4F
        return s == 0 ? 0xbeef : s
    }

    /// Same calendar day + same `daySalt` → same ordered slice (deterministic).
    static func dailyChallenge(from pool: [QuizQuestion], count: Int, daySalt: String) -> [QuizQuestion] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let base = UInt64(bitPattern: Int64(start.timeIntervalSince1970))
        let seed = mixDaySeed(base == 0 ? 0xfeed : base, salt: daySalt, count: count)
        var gen = SeededRandomNumberGenerator(seed: seed)
        let shuffled = pool.shuffled(using: &gen)
        return Array(shuffled.prefix(min(count, shuffled.count)))
    }

    static func practiceRound(from pool: [QuizQuestion], count: Int, practiceSalt: String) -> [QuizQuestion] {
        var seed = UInt64.random(in: 1 ... (UInt64.max - 1))
        seed = mixDaySeed(seed, salt: practiceSalt, count: count)
        var gen = SeededRandomNumberGenerator(seed: seed)
        let shuffled = pool.shuffled(using: &gen)
        return Array(shuffled.prefix(min(count, shuffled.count)))
    }
}
