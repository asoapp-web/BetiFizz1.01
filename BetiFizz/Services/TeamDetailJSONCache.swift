//
//  TeamDetailJSONCache.swift
//  BetiFizz
//
//  Persists team + squad as JSON under Application Support so reopening a team
//  does not hit the API until the cache expires.
//

import Foundation

enum TeamDetailJSONCache {
    private static let ttl: TimeInterval = 30 * 24 * 60 * 60
    private static let subfolder = "TeamDetailCache"

    private static var folderURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("BetiFizz", isDirectory: true)
            .appendingPathComponent(subfolder, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func fileURL(teamId: String) -> URL {
        // Safe filename: numeric ids only from API, still sanitize
        let safe = teamId.replacingOccurrences(of: "/", with: "_")
        return folderURL.appendingPathComponent("\(safe).json")
    }

    struct Payload: Codable {
        let fetchedAt: Date
        let team: Team
        let squad: [SquadEntry]
    }

    struct SquadEntry: Codable {
        let id: String
        let name: String
        let position: String?
        let shirtNumber: Int?
    }

    static func load(teamId: String) -> Payload? {
        let url = fileURL(teamId: teamId)
        guard let data = try? Data(contentsOf: url),
              let p = try? JSONDecoder().decode(Payload.self, from: data),
              p.fetchedAt.addingTimeInterval(ttl) > Date()
        else { return nil }
        return p
    }

    static func save(teamId: String, team: Team, squad: [BetiFizzSquadPlayer]) {
        let entries = squad.map {
            SquadEntry(id: $0.id, name: $0.name, position: $0.position, shirtNumber: $0.shirtNumber)
        }
        let payload = Payload(fetchedAt: Date(), team: team, squad: entries)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL(teamId: teamId), options: .atomic)
    }
}
