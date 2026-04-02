//
//  FootballDataOrgClient.swift
//  BetiFizz
//
//  football-data.org v4 client. All traffic is logged via BetiFizzLogger.
//

import Foundation

final class FootballDataOrgClient {
    static let shared = FootballDataOrgClient()

    private let baseURL = "https://api.football-data.org/v4"
    private let session: URLSession
    private var requestTimestamps: [Date] = []
    private let rateLimit = 10
    private let rateWindow: TimeInterval = 60

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        session = URLSession(configuration: cfg)
    }

    func fetch<T: Decodable>(endpoint: String, as type: T.Type) async throws -> T {
        let key = BetiFizzAPIConfig.footballDataOrgKey
        guard !key.isEmpty else {
            BetiFizzLogger.logError(BetiFizzAPIError.missingAPIKey)
            throw BetiFizzAPIError.missingAPIKey
        }

        try await waitForRateLimit()

        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            BetiFizzLogger.logError(BetiFizzAPIError.invalidURL)
            throw BetiFizzAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        let headers: [String: String] = [
            "X-Auth-Token": key,
            "Accept": "application/json",
        ]
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        BetiFizzLogger.logRequest(url: url, headers: headers)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if Self.isCancellation(error) {
                BetiFizzLogger.info("Request cancelled (e.g. SwiftUI task replaced): \(url.lastPathComponent)")
            } else {
                BetiFizzLogger.logError(error, url: url)
            }
            throw error
        }

        requestTimestamps.append(Date())

        guard let http = response as? HTTPURLResponse else {
            let err = BetiFizzAPIError.invalidResponse
            BetiFizzLogger.logError(err, url: url)
            throw err
        }

        BetiFizzLogger.logResponse(url: url, statusCode: http.statusCode, data: data)

        if http.statusCode == 429 {
            throw BetiFizzAPIError.rateLimitExceeded
        }
        guard (200...299).contains(http.statusCode) else {
            throw BetiFizzAPIError.httpError(statusCode: http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            BetiFizzLogger.logError(error, url: url)
            throw BetiFizzAPIError.decodingError(error)
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let ns = error as NSError
        return ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled
    }

    private func waitForRateLimit() async throws {
        let now = Date()
        requestTimestamps.removeAll { now.timeIntervalSince($0) > rateWindow }
        if requestTimestamps.count >= rateLimit {
            let oldest = requestTimestamps.min() ?? now
            let wait = rateWindow - now.timeIntervalSince(oldest)
            if wait > 0 {
                BetiFizzLogger.info("Rate limit: waiting \(Int(wait))s before next request")
                try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
        }
    }
}
