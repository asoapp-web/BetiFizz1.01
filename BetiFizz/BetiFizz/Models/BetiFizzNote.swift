//
//  BetiFizzNote.swift
//  BetiFizz
//

import Foundation

struct BetiFizzNote: Codable, Identifiable, Equatable {
    var id: String
    var text: String
    var imageData: Data?
    var linkedMatchId: String?
    var linkedMatchSummary: String?
    var linkedTeamId: String?
    var linkedTeamName: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        text: String = "",
        imageData: Data? = nil,
        linkedMatchId: String? = nil,
        linkedMatchSummary: String? = nil,
        linkedTeamId: String? = nil,
        linkedTeamName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id; self.text = text; self.imageData = imageData
        self.linkedMatchId = linkedMatchId; self.linkedMatchSummary = linkedMatchSummary
        self.linkedTeamId = linkedTeamId; self.linkedTeamName = linkedTeamName
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }

    var titlePreview: String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "Empty note" }
        let line = t.replacingOccurrences(of: "\n", with: " ")
        return line.count > 60 ? String(line.prefix(60)) + "…" : line
    }
}

// MARK: - Store

final class BetiFizzNotesStore {
    static let shared = BetiFizzNotesStore()
    private let key = "BetiFizz.notes.v1"
    private init() {}

    var notes: [BetiFizzNote] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode([BetiFizzNote].self, from: data)
            else { return [] }
            return decoded.sorted { $0.updatedAt > $1.updatedAt }
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }

    func add(_ note: BetiFizzNote) {
        var list = notes; list.removeAll { $0.id == note.id }
        list.insert(note, at: 0); notes = list
    }

    func update(_ note: BetiFizzNote) {
        var list = notes
        if let idx = list.firstIndex(where: { $0.id == note.id }) {
            var n = note; n.updatedAt = Date(); list[idx] = n
        } else { list.insert(note, at: 0) }
        notes = list
    }

    func delete(noteId: String) {
        var list = notes; list.removeAll { $0.id == noteId }; notes = list
    }

    func note(byId id: String) -> BetiFizzNote? { notes.first { $0.id == id } }
}
