//
//  SongHistoryManager.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-30.
//

import CoreData
import Foundation
import SwiftUI

class SongHistoryManager {
    private static let maxEntries = 273
    private static let historyFilename = "song_history.json" // legacy file we migrate from
    private static var persistentContainer: NSPersistentContainer = PersistenceController.shared.container

    @AppStorage("coreDataHistoryMigrated") private static var coreDataHistoryMigrated: Bool = false

    private static var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// Allow tests to inject an in‑memory container.
    static func configure(container: NSPersistentContainer) {
        persistentContainer = container
    }

    // MARK: - Migration from legacy JSON

    /// Migrates legacy JSON entries into Core Data, optionally correcting them via iTunes API.
    static func migrateRawEntries(completion: @escaping () -> Void) {
        if coreDataHistoryMigrated {
            completion()
            return
        }

        let legacyHistory = loadLegacyHistory()
        guard !legacyHistory.isEmpty else {
            coreDataHistoryMigrated = true
            completion()
            return
        }

        let group = DispatchGroup()
        var corrected: [SongSuggestionHistoryEntry] = []
        corrected.reserveCapacity(legacyHistory.count)

        for entry in legacyHistory {
            group.enter()
            APIService.searchSongOniTunes(song: entry.title, artist: entry.artist) { result in
                if let result = result {
                    let newEntry = SongSuggestionHistoryEntry(
                        title: result.trackName,
                        artist: result.artistName,
                        date: entry.date,   // preserve original date
                        emoji: entry.emoji  // preserve original mood
                    )
                    corrected.append(newEntry)
                } else {
                    print("⚠️ Could not correct legacy track: \(entry.title) by \(entry.artist)")
                    corrected.append(entry)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            replaceAll(with: corrected)
            coreDataHistoryMigrated = true
            print("✅ Song history migration to Core Data completed.")
            completion()
        }
    }

    // MARK: - Public API

    static func loadHistory() -> [SongSuggestionHistoryEntry] {
        var entries: [SongSuggestionHistoryEntry] = []
        viewContext.performAndWait {
            let request: NSFetchRequest<SongHistory> = SongHistory.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            if let result = try? viewContext.fetch(request) {
                entries = result.map { $0.asHistoryEntry() }
            }
        }
        return entries
    }

    /// Saves an entire history array (used mainly by tests).
    static func saveHistory(_ history: [SongSuggestionHistoryEntry]) {
        replaceAll(with: history)
    }

    static func isDuplicate(_ newEntry: SongSuggestionHistoryEntry) -> Bool {
        var count = 0
        viewContext.performAndWait {
            let request: NSFetchRequest<SongHistory> = SongHistory.fetchRequest()
            request.predicate = NSPredicate(format: "title == %@ AND artist == %@", newEntry.title, newEntry.artist)
            request.fetchLimit = 1
            count = (try? viewContext.count(for: request)) ?? 0
        }
        return count > 0
    }

    static func addToHistory(_ entry: SongSuggestionHistoryEntry) {
        viewContext.performAndWait {
            let request: NSFetchRequest<SongHistory> = SongHistory.fetchRequest()
            request.predicate = NSPredicate(format: "title == %@ AND artist == %@", entry.title, entry.artist)
            request.fetchLimit = 1

            if let duplicateCount = try? viewContext.count(for: request), duplicateCount > 0 {
                return
            }

            let history = SongHistory(context: viewContext)
            history.title = entry.title
            history.artist = entry.artist
            history.date = entry.date
            history.emoji = entry.emoji

            trimExcessEntries(in: viewContext)
            try? viewContext.save()
        }
    }

    // MARK: - Helpers

    private static func trimExcessEntries(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<SongHistory> = SongHistory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        guard let results = try? context.fetch(request), results.count > maxEntries else { return }
        let overflow = results.count - maxEntries
        results.prefix(overflow).forEach { context.delete($0) }
    }

    private static func replaceAll(with entries: [SongSuggestionHistoryEntry]) {
        viewContext.performAndWait {
            let fetch: NSFetchRequest<SongHistory> = SongHistory.fetchRequest()
            if let existing = try? viewContext.fetch(fetch) {
                existing.forEach { viewContext.delete($0) }
            }

            // Keep only the most recent `maxEntries` items to match previous behavior.
            let trimmed = Array(entries.suffix(maxEntries))
            for entry in trimmed {
                let history = SongHistory(context: viewContext)
                history.title = entry.title
                history.artist = entry.artist
                history.date = entry.date
                history.emoji = entry.emoji
            }

            trimExcessEntries(in: viewContext)
            try? viewContext.save()
        }
    }

    private static var legacyFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(historyFilename)
    }

    /// Reads the old JSON history file if it exists.
    private static func loadLegacyHistory() -> [SongSuggestionHistoryEntry] {
        guard
            let url = legacyFileURL,
            let data = try? Data(contentsOf: url),
            let history = try? JSONDecoder().decode([SongSuggestionHistoryEntry].self, from: data)
        else {
            return []
        }
        return history
    }
}
