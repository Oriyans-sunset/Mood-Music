//
//  APIService.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-26.
//

import Foundation

struct SpotifyTrack: Decodable {
    let album: Album
    let external_urls: [String: String]

    struct Album: Decodable {
        let images: [Image]
        struct Image: Decodable { let url: String }
    }
}

struct SpotifySearchResponse: Decodable {
    let tracks: Tracks
    struct Tracks: Decodable {
        let items: [SpotifyTrack]
    }
}

struct APIService {
    
    private static func requestSong(prompt: String, completion: @escaping (String?) -> Void) {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
        if apiKey.isEmpty {
            print("❌ OPENAI_API_KEY is missing! Make sure Secrets.xcconfig exists and is configured.")
        }
        
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Authorization": "Bearer \(apiKey)",
            "Content-type": "application/json"
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a music recommendation assistant."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 100
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            //print("Failed to encode body")
            completion(nil)
            return
        }
        
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                //print("Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                //print("No data received")
                completion(nil)
                return
            }
            
            do {
                let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let content = result.choices.first?.message.content {
                    completion(content)
                } else {
                    completion(nil)
                }
            } catch {
                //print("Error decoding OpenAI response: \(error)")
                //print("Raw response: \(String(data: data, encoding: .utf8) ?? "")")
                completion(nil)
            }
        }.resume()
    }
    
    static func getSongSuggestion(for moodText: String, completion: @escaping (String?) -> Void) {
        let prompt = """
        Give me a fun and underrated '\(moodText)' mood song recommendation. Try not to repeat popular choices. Return only a JSON object in this format with **no markdown, no explanation**:
        {
          "title": "Song Title",
          "artist": "Artist Name"
        }
        """
        requestSong(prompt: prompt, completion: completion)
    }
    
    static func getSurpriseSongSuggestion(for moodText: String,
                                          avoiding primary: SongSuggestion,
                                          completion: @escaping (SongSuggestion?) -> Void) {
        let prompt = """
        The listener chose the '\(moodText)' mood and already got "\(primary.title)" by "\(primary.artist)". Suggest one different bonus track that shares the same vibe but feels like a detour. Avoid remixes or covers of that song. Return only a JSON object:
        {
          "title": "Song Title",
          "artist": "Artist Name"
        }
        """
        requestSong(prompt: prompt) { content in
            guard let content = content,
                  let jsonData = content.data(using: .utf8),
                  let suggestion = try? JSONDecoder().decode(SongSuggestion.self, from: jsonData) else {
                completion(nil)
                return
            }
            
            let sameTitle = suggestion.title.caseInsensitiveCompare(primary.title) == .orderedSame
            let sameArtist = suggestion.artist.caseInsensitiveCompare(primary.artist) == .orderedSame
            if sameTitle && sameArtist {
                completion(nil)
                return
            }
            
            completion(suggestion)
        }
    }
    
    static func getNonDuplicateSongSuggestion(for moodText: String, maxRetries: Int = 3, completion: @escaping (SongSuggestion?) -> Void) {
        var attempts = 0
        
        func tryFetch() {
            getSongSuggestion(for: moodText) { result in
                guard let content = result as String?,
                      let jsonData = content.data(using: String.Encoding.utf8),
                      let rawSuggestion = try? JSONDecoder().decode(SongSuggestion.self, from: jsonData) else {
                    completion(nil)
                    return
                }
                
                searchSongOniTunes(song: rawSuggestion.title, artist: rawSuggestion.artist) { iTunesResult in
                    guard let iTunesResult = iTunesResult else {
                        completion(nil)
                        return
                    }
                    
                    let correctedEntry = SongSuggestionHistoryEntry(title: iTunesResult.trackName,
                                                                   artist: iTunesResult.artistName,
                                                                   date: Date(),
                                                                   emoji: moodText)
                    
                    if SongHistoryManager.isDuplicate(correctedEntry) {
                        attempts += 1
                        if attempts < maxRetries {
                            tryFetch()
                        } else {
                            completion(nil)
                        }
                    } else {
                        SongHistoryManager.addToHistory(correctedEntry)
                        let correctedSuggestion = SongSuggestion(title: iTunesResult.trackName, artist: iTunesResult.artistName)
                        completion(correctedSuggestion)
                    }
                }
            }
        }

        tryFetch()
    }

    
    static func searchSongOniTunes(song: String,
                                   artist: String,
                                   completion: @escaping (iTunesSongResult?) -> Void) {

        // Helper for building a search URL
        func makeURL(term: String, attribute: String) -> URL? {
            let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            // we default to U.S. store here; you can swap in Locale.current if you prefer
            return URL(string: "https://itunes.apple.com/search?term=\(encoded)&media=music&attribute=\(attribute)&limit=25&country=US")
        }

        // Local copies to hold results so that we can fall back gracefully
        var titleResults: [iTunesSongResult] = []

        // 1️⃣ TITLE‑ONLY SEARCH
        guard let titleURL = makeURL(term: song, attribute: "songTerm") else {
            completion(nil); return
        }

        func runArtistSearch() {
            // 2️⃣ ARTIST‑ONLY SEARCH
            guard let artistURL = makeURL(term: artist, attribute: "artistTerm") else {
                // No artist URL – fall back to *any* title result if we have one
                completion(titleResults.first); return
            }

            URLSession.shared.dataTask(with: artistURL) { data, _, _ in
                guard
                    let data = data,
                    let response = try? JSONDecoder().decode(iTunesSearchResponse.self, from: data)
                else {
                    // Network / decode error – return first title result if available
                    completion(titleResults.first); return
                }

                // Look for a track whose *title* matches (case‑insensitive)
                if let exactPair = response.results.first(where: {
                    $0.trackName.caseInsensitiveCompare(song) == .orderedSame
                }) {
                    completion(exactPair)
                } else if !titleResults.isEmpty {
                    // No exact pair – return the best title‑only hit
                    completion(titleResults.first)
                } else {
                    // Finally, give at least *something* from the artist search
                    completion(response.results.first)
                }
            }.resume()
        }

        // Fire the title‑only search first
        URLSession.shared.dataTask(with: titleURL) { data, _, _ in
            guard
                let data = data,
                let response = try? JSONDecoder().decode(iTunesSearchResponse.self, from: data)
            else {
                // If that failed outright, move straight to artist search
                runArtistSearch(); return
            }

            // Save all title results for potential fallback
            titleResults = response.results

            // Look for the exact artist match
            if let exact = response.results.first(where: {
                $0.artistName.caseInsensitiveCompare(artist) == .orderedSame
            }) {
                completion(exact)
            } else {
                // No exact – try artist search next
                runArtistSearch()
            }
        }.resume()
    }
    
    static func searchSongOnSpotify(song: String,
                                    artist: String,
                                    completion: @escaping (String?, String?) -> Void) {
        // completion: (coverArtURL, spotifyLink)
        
        getSpotifyAccessToken { token in
            guard let token = token else { completion(nil, nil); return }

            let query = "track:\(song) artist:\(artist)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

            let url = URL(string: "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=1")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let data = data,
                      let response = try? JSONDecoder().decode(SpotifySearchResponse.self, from: data),
                      let track = response.tracks.items.first else {
                    print("❌ Spotify search error: could not decode response")
                    completion(nil, nil)
                    return
                }
                
                let coverURL = track.album.images.first?.url
                let spotifyLink = track.external_urls["spotify"]
                completion(coverURL, spotifyLink)
            }.resume()
        }
    }
    private static func getSpotifyAccessToken(completion: @escaping (String?) -> Void) {
        let clientId = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_ID") as? String ?? ""
        let clientSecret = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_SECRET") as? String ?? ""
        
        if clientId.isEmpty {
            print("❌ SPOTIFY_CLIENT_ID is missing! Make sure Secrets.xcconfig exists and is configured.")
        }
        
        if clientSecret.isEmpty {
            print("❌ SPOTIFY_CLIENT_SECRET is missing! Make sure Secrets.xcconfig exists and is configured.")
        }
        
        guard let credentialData = "\(clientId):\(clientSecret)".data(using: .utf8) else {
            completion(nil); return
        }

        let base64Credentials = credentialData.base64EncodedString()
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["access_token"] as? String else {
                print("❌ Spotify auth error: failed to get access token")
                completion(nil); return
            }
            completion(token)
        }.resume()
    }
}
