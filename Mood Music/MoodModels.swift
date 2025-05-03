//
//  MoodModels.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-25.
//
import SwiftUI

// for calnder view
struct MoodLog {
    let day: String
    let moodText: String?
    let entry: SongSuggestionHistoryEntry?
}

// Make a custom hashable fucntion, in which just compare day and mood text for uniqueness
// Ignore the entry when hashing (it’s not needed to identify calendar dots anyway)
extension MoodLog: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(day)
        hasher.combine(moodText)
    }

    static func == (lhs: MoodLog, rhs: MoodLog) -> Bool {
        return lhs.day == rhs.day && lhs.moodText == rhs.moodText
    }
}

let moodLabels: [String: String] = [
    "😊": "Happy",
    "😐": "Meh",
    "😔": "Sad",
    "🤩": "Excited",
    "🥱": "Tired",
    "😣": "Anxious"
]

let moodTextColours: [String: Color] = [
    "Happy": .yellow,
    "Meh": .gray,
    "Sad": .blue,
    "Excited": .orange,
    "Tired": .indigo,
    "Anxious": .red
]

