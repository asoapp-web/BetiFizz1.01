//
//  QuizQuestionsLoader.swift
//  BetiFizz
//

import Foundation

enum QuizQuestionsLoader {
    private static let resourceName = "quiz_questions"

    static func loadDefaultDeck() throws -> [QuizQuestion] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw QuizLoadError.missingFile
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([QuizQuestion].self, from: data)
    }

    enum QuizLoadError: Error {
        case missingFile
    }
}
