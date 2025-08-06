//
//  APIService.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-26.
//

import Foundation

struct APIService {
    
    static func getSongSuggestion(for moodText: String, completion: @escaping (String?) -> Void) {
        let prompt = """
        Give me a fun and underrated '\(moodText)' mood song recommendation. Try not to repeat popular choices. Return only a JSON object in this format with **no markdown, no explanation**:
        {
          "title": "Song Title",
          "artist": "Artist Name"
        }
        """
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
    
    static func getNonDuplicateSongSuggestion(for moodText: String, maxRetries: Int = 3, completion: @escaping (SongSuggestion?) -> Void) {
        var attempts = 0
        
        func tryFetch() {
            // call the fucntion to get the suggestion
            getSongSuggestion(for: moodText) { result in
                guard let content = result as String?,
                      let jsonData = content.data(using: String.Encoding.utf8),
                      let suggestion = try? JSONDecoder().decode(SongSuggestion.self, from: jsonData) else {
                    completion(nil)
                    return
                }

                let entry = SongSuggestionHistoryEntry(title: suggestion.title,
                                                       artist: suggestion.artist,
                                                       date: Date(),
                                                       emoji: moodText)
                
                if SongHistoryManager.isDuplicate(entry) {
                    //print("attempt")
                    attempts += 1
                    if attempts < maxRetries {
                        //print("Duplicate found: \(entry). Retrying (\(attempts)/\(maxRetries))...")
                        tryFetch()
                    } else {
                        //print("No unique suggestion found after \(maxRetries) attempts.")
                        completion(nil)
                    }
                } else {
                    SongHistoryManager.addToHistory(entry)
                    completion(suggestion)
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
}
