//
//  QuizQuestion.swift
//  BetiFizz
//

import Foundation

struct QuizQuestion: Identifiable, Codable, Equatable {
    let id: String
    let question: String
    let options: [String]
    /// Index into `options` for the correct answer.
    let correctIndex: Int

    var correctAnswer: String {
        guard options.indices.contains(correctIndex) else { return "" }
        return options[correctIndex]
    }
}
