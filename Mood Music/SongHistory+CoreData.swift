//
//  SongHistory+CoreData.swift
//  Mood Music
//
//  Created by Codex on 2025-XX-XX.
//

import CoreData
import Foundation

@objc(SongHistory)
final class SongHistory: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SongHistory> {
        NSFetchRequest<SongHistory>(entityName: "SongHistory")
    }
}

extension SongHistory {
    @NSManaged var title: String
    @NSManaged var artist: String
    @NSManaged var date: Date
    @NSManaged var emoji: String

    func asHistoryEntry() -> SongSuggestionHistoryEntry {
        SongSuggestionHistoryEntry(title: title, artist: artist, date: date, emoji: emoji)
    }
}
