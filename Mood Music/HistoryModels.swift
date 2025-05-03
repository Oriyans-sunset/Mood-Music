//
//  Untitled.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-30.
//
import Foundation

struct SongSuggestionHistoryEntry: Codable, Equatable {
    let title: String
    let artist: String
    let date: Date
    let emoji: String
}
