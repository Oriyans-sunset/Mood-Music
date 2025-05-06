//
//  ItunesModels.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-26.
//

struct iTunesSongResult: Codable {
    let trackName: String      // Song title
    let artistName: String     // Artist
    let artworkUrl100: String
    let trackViewUrl: String
}

struct iTunesSearchResponse: Codable {
    let results: [iTunesSongResult]
}
