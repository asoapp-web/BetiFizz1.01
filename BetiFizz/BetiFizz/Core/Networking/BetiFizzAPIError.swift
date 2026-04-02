//
//  BetiFizzAPIError.swift
//  BetiFizz
//

import Foundation

enum BetiFizzAPIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case rateLimitExceeded
    case decodingError(Error)
    case dateRangeInvalid
    case dateRangeExceedsApiLimit

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Set your football-data.org token in FootballDataToken.swift (see comments in that file)."
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "Server error (\(code))"
        case .rateLimitExceeded:
            return "Too many requests. Try again in about a minute."
        case .decodingError(let e):
            return "Could not read data: \(e.localizedDescription)"
        case .dateRangeInvalid:
            return "Invalid date range (start after end)."
        case .dateRangeExceedsApiLimit:
            return "football-data.org allows at most 10 days per request. Shorten the range."
        }
    }
}
