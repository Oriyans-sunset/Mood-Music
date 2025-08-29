//
//  SongHistoryManager.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-30.
//

import Foundation
import SwiftUI

class SongHistoryManager {
    private static let historyFilename = "song_history.json"
    private static let maxEntries = 273
    
    @AppStorage("historyMigrated") private static var historyMigrated: Bool = false
    
    // Migrates raw history entries by correcting them via iTunes API
    static func migrateRawEntries(completion: @escaping () -> Void) {
        if historyMigrated {
            completion()
            return
        }
        var history = loadHistory()
        let group = DispatchGroup()
        for (idx, entry) in history.enumerated() {
            group.enter()
            APIService.searchSongOniTunes(song: entry.title, artist: entry.artist) { result in
                if let result = result {
                    let newEntry = SongSuggestionHistoryEntry(
                        title: result.trackName,
                        artist: result.artistName,
                        date: entry.date,   // preserve original date
                        emoji: entry.emoji  // preserve original mood
                    )
                    history[idx] = newEntry
                } else {
                    // 🔹 Error fallback: keep the original raw entry
                    print("⚠️ Could find a correct track from OPEN AI API suggestions: \(entry.title) by \(entry.artist)")
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            saveHistory(history)
            historyMigrated = true
            print("✅ Song history migration completed.")
            completion()
        }
    }

    private static var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(historyFilename)
    }

    static func loadHistory() -> [SongSuggestionHistoryEntry] {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url),
              let history = try? JSONDecoder().decode([SongSuggestionHistoryEntry].self, from: data) else {
            return []
        }
        return history
    }

    static func saveHistory(_ history: [SongSuggestionHistoryEntry]) {
        guard let url = fileURL else { return }
        if let data = try? JSONEncoder().encode(history) {
            try? data.write(to: url)
        }
    }

   
    static func isDuplicate(_ newEntry: SongSuggestionHistoryEntry) -> Bool {
        //print("🧪 Comparing against history:")
        for past in loadHistory() {
            //print("- \(past.title) by \(past.artist)")
            if past.title == newEntry.title && past.artist == newEntry.artist {
                //print("🔍 Duplicate found for \(newEntry.title) by \(newEntry.artist)")
                return true
            }
        }
        return false
    }

    

    static func addToHistory(_ entry: SongSuggestionHistoryEntry) {
        var history = loadHistory()
        history.append(entry)
        if history.count > maxEntries {
            history.removeFirst(history.count - maxEntries)
        }
        saveHistory(history)
    }
}
