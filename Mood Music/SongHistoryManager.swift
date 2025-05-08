//
//  SongHistoryManager.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-30.
//

import Foundation

class SongHistoryManager {
    private static let historyFilename = "song_history.json"
    private static let maxEntries = 14

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
