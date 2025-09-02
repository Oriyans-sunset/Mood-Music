//
//  MoodModels.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-25.
//
import SwiftUI

// for calendar view
struct MoodLog {
    let date: Date
    let day: String
    let moodText: String?
    let entry: SongSuggestionHistoryEntry?
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

