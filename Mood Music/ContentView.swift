//
//  ContentView.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-23.
//

import SwiftUI

struct MoodLog: Hashable {
    let day: String
    let colour: Color
}

let moodLabels: [String: String] = [
    "😊": "Happy",
    "😐": "Meh",
    "😔": "Sad",
    "🤩": "Excited",
    "🥱": "Tired",
    "😣": "Anxious"
]

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

struct ContentView: View {
    // state varibles
    @State private var selectedMood:String? = nil
    @State private var suggestedSong:String? = nil
    @State private var pastWeek: [MoodLog] = [
        MoodLog(day: "S", colour: .yellow),
        MoodLog(day: "M", colour: .orange),
        MoodLog(day: "T", colour: .blue),
        MoodLog(day: "W", colour: .gray),
        MoodLog(day: "Th", colour: .blue),
        MoodLog(day: "F", colour: .purple),
        MoodLog(day: "Sa", colour: .orange),
    ]
    
    var body: some View {
        ZStack{
            LinearGradient(
                gradient: Gradient(colors: [.mint, .white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                Text("How are you feeling today?")
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 50))
                    .fontWeight(.bold)
                
                
                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]
                
                
                
                let moodColours: [String: Color] = [
                    "😊": .yellow,
                    "😐": .gray,
                    "😔": .blue,
                    "🤩": .orange,
                    "🥱": .indigo,
                    "😣": .red
                ]
                
                LazyVGrid(columns: columns, spacing: 30){
                    ForEach(Array(moodLabels.keys), id: \.self) { emoji in
                        Button(action: {
                            selectedMood = emoji
                        }) {
                            VStack(spacing: 8){
                                Text(emoji)
                                    .font(.system(size: 50))
                                    .frame(width: 100, height: 100)
                                    .background(moodColours[emoji, default: .gray].opacity(0.7))
                                    .clipShape(Circle())
                                Text(moodLabels[emoji, default: "mood"])
                                    .font(.system(size: 20))
                                    .fontWeight(.medium)
                                    .foregroundColor(.black)
                            }
                            
                        }
                    }
                }
                
                
                VStack(spacing: 12) {
                    HStack(spacing: 12){
                        ForEach(pastWeek, id: \.self) { entry in
                            ZStack {
                                Circle()
                                    .fill(entry.colour)
                                    .frame(width: 32, height: 32)
                                
                                Text(entry.day)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(.black)
                    .cornerRadius(20)
                    
                }.padding()
                
                Button(action :{
                    getSongSuggestion(for: selectedMood ?? "😐") //api call to openai
                }) {
                    Text("Submit")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.black)
                        .cornerRadius(20)
                }
                .padding(.horizontal)
                
            }
            
            if let song = suggestedSong {
                VStack{
                    Spacer()
                    
                    let parts = song.components(separatedBy: " - ")
                    SongSuggestionCard(title: parts.first ?? "Unknown Title", artist: parts.last ?? "Unknown Artist", image: Image("placeholder")
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeOut(duration: 0.5), value: song)
                }
                .padding(.bottom, 40)
            }
            
        }
        .allowsHitTesting(suggestedSong == nil)
    }
    
    
    struct SongSuggestionCard: View {
        let title: String
        let artist: String
        let image: Image
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 280)
                    .clipped()
                    .cornerRadius(16)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
            }
            .padding()
            .background(.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal)
        }
    }
    
    func getSongSuggestion(for emoji: String){
        guard let moodText = moodLabels[emoji] else {return}
        
        let prompt = """
            Suggest a song that matches the mood '\(moodText)'. Return only a JSON object in this format:
            {
              "title": "Song Title",
              "artist": "Artist Name"
            }
            """
        
        let apiKey = ""
        
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let headers = [
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
        
        // Converts the Swift dictionary into JSON data so it can be sent with the HTTP request.
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("Failed to enocde body.")
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                // takes the raw JSON from OpenAI and tries to map it into your OpenAIResponse struct.
                let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                if let content = result.choices.first?.message.content {
                    
                    // The content here is a JSON string inside a string. Like "{"title":"Let It Be","artist":"The Beatles"}".
                    // You first convert that string into actual Data using .data(using: .utf8) so it can be decoded again.
                    if let jsonData = content.data(using: .utf8) {
                        let suggestion = try JSONDecoder().decode(SongSuggestion.self, from: jsonData)
                        
                        // Because all network calls are off the main thread, you have to switch back using DispatchQueue.main.async to safely update UI.
                        DispatchQueue.main.async {
                            self.suggestedSong = "\(suggestion.title) - \(suggestion.artist)"
                        }
                    } else {
                        print("Failed to convert content to Data.")
                    }
                }
            } catch {
                print("Error decoding: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }.resume()
        
    }
    
}


#Preview{
    ContentView()
}
