//
//  CalenderTapHandler.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-09-02.
//

import SwiftUI

func handleCalendarTap(
    log: MoodLog,
    preferredMusicProvider: String,
    albumArtURL: Binding<URL?>,
    albumURL: Binding<URL?>,
    suggestedSong: Binding<String?>
) {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()

    if let entry = log.entry {
        albumArtURL.wrappedValue = nil
        albumURL.wrappedValue = nil

        if preferredMusicProvider == "Apple Music" {
            APIService.searchSongOniTunes(song: entry.title, artist: entry.artist) { result in
                DispatchQueue.main.async {
                    if let result = result {
                        albumArtURL.wrappedValue = URL(
                            string: result.artworkUrl100.replacingOccurrences(of: "100x100bb.jpg", with: "500x500bb.jpg")
                        )
                        albumURL.wrappedValue = URL(string: result.trackViewUrl)
                        suggestedSong.wrappedValue = "\(result.trackName) - \(result.artistName)"
                    }
                }
            }
        } else {
            APIService.searchSongOniTunes(song: entry.title, artist: entry.artist) { result in
                DispatchQueue.main.async {
                    if let result = result {
                        APIService.searchSongOnSpotify(song: result.trackName, artist: result.artistName) { coverURL, spotifyLink in
                            DispatchQueue.main.async {
                                albumArtURL.wrappedValue = coverURL != nil ? URL(string: coverURL!) : nil
                                albumURL.wrappedValue = spotifyLink != nil ? URL(string: spotifyLink!) : nil
                                suggestedSong.wrappedValue = "\(result.trackName) - \(result.artistName)"
                            }
                        }
                    } else {
                        APIService.searchSongOnSpotify(song: entry.title, artist: entry.artist) { coverURL, spotifyLink in
                            DispatchQueue.main.async {
                                albumArtURL.wrappedValue = coverURL != nil ? URL(string: coverURL!) : nil
                                albumURL.wrappedValue = spotifyLink != nil ? URL(string: spotifyLink!) : nil
                                suggestedSong.wrappedValue = "\(entry.title) - \(entry.artist)"
                            }
                        }
                    }
                }
            }
        }
    }
}
