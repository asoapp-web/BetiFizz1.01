//
//  FavoriteTeamRepository.swift
//  BetiFizz
//

import CoreData
import Foundation

extension Notification.Name {
    static let betiFizzFavoritesDidChange = Notification.Name("betiFizzFavoritesDidChange")
}

enum FavoriteTeamRepository {
    static func isFavorite(teamId: String, in context: NSManagedObjectContext) -> Bool {
        var found = false
        context.performAndWait {
            let r = FavoriteTeam.fetchRequest()
            r.predicate = NSPredicate(format: "remoteId == %@", teamId)
            r.fetchLimit = 1
            found = ((try? context.count(for: r)) ?? 0) > 0
        }
        return found
    }

    static func toggle(teamId: String, name: String, crestURL: String?, in context: NSManagedObjectContext) {
        context.performAndWait {
            let r = FavoriteTeam.fetchRequest()
            r.predicate = NSPredicate(format: "remoteId == %@", teamId)
            r.fetchLimit = 1
            if let existing = try? context.fetch(r).first {
                context.delete(existing)
            } else {
                let e = FavoriteTeam(context: context)
                e.remoteId = teamId
                e.name = name
                e.crestURL = crestURL
                e.addedAt = Date()
            }
            try? context.save()
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .betiFizzFavoritesDidChange, object: nil)
        }
    }
}
