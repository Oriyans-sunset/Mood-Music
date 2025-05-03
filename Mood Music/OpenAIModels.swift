//
//  OpenAIModels.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-25.
//

import Foundation

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

struct SongSuggestion: Codable {
    let title: String
    let artist: String
}
