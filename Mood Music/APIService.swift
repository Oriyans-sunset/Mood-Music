//
//  APIService.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-26.
//

import Foundation

#if EXTERNAL_CONFIG
let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
#else
let apiKey = "PLACEHOLDER_IF_NEEDED"
#endif

struct APIService {
    
    static func getSongSuggestion(for moodText: String, completion: @escaping (String?) -> Void) {
        let prompt = """
        Give me a fun and underrated '\(moodText)' mood song recommendation. Try not to repeat popular choices. Return only a JSON object in this format:
        {
          "title": "Song Title",
          "artist": "Artist Name"
        }
        """
        
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
            print("Failed to encode body")
            completion(nil)
            return
        }
        
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
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
                print("Error decoding OpenAI response: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "")")
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
                    print("attempt")
                    attempts += 1
                    if attempts < maxRetries {
                        print("Duplicate found: \(entry). Retrying (\(attempts)/\(maxRetries))...")
                        tryFetch()
                    } else {
                        print("No unique suggestion found after \(maxRetries) attempts.")
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

    
    static func searchSongOniTunes(song: String, artist: String, completion: @escaping (iTunesSongResult?) -> Void) {
        
        let countryCode = Locale.current.region?.identifier ?? "US" // detect country for accurate url for ituens search
        
        let query = "\(song) \(artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://itunes.apple.com/search?term=\(query)&country=\(countryCode)&entity=song&limit=1"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                let searchResponse = try JSONDecoder().decode(iTunesSearchResponse.self, from: data)
                
                completion(searchResponse.results.first)
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
