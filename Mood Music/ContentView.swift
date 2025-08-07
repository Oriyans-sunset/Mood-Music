//
//  ContentView.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-23.
//

import SwiftUI

enum Route: Hashable {
    case settings
}

struct ContentView: View {
    
    @State private var path = NavigationPath()

    @State private var albumArtURL: URL? = nil
    @State private var albumURL: URL? = nil
    
    @State private var isLoading: Bool = false
    
    @State private var selectedMood:String? = nil
    @State private var suggestedSong:String? = nil
    @State private var pastWeek: [MoodLog] = [] // calender days colour mapping hardocded for now
    
    // used multiple times so we made it a var
    private static let lastCheckInKey = "lastCheckInDate"
    
    
    @State private var hasSubmittedToday: Bool = {
        if let saved = UserDefaults.standard.object(forKey: lastCheckInKey) as? Date {
            return Calendar.current.isDateInToday(saved)
        }
        return false
    }()
    
    // varible defined for opneing external links
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack{
                LinearGradient(
                    gradient: Gradient(colors: [.white, .mint]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    ZStack {
                        // Center the heading text
                        Text("How are you feeling today?")
                            .multilineTextAlignment(.center)
                            .font(.custom("Pacifico-Regular", size: 50))
                            .fontWeight(.bold)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .foregroundColor(.mint)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 5)
                        
                        // Absolute position for settings button
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    path.append(Route.settings)
                                }) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                                .padding(.trailing, 16)
                                .padding(.top, 12)
                            }
                            Spacer()
                        }
                    }
                    
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
                    
                    // emoji buttons
                    LazyVGrid(columns: columns, spacing: 30){
                        ForEach(Array(moodLabels.keys), id: \.self) { emoji in
                            Button(action: {
                                triggerHaptic()
                                selectedMood = emoji
                            }) {
                                VStack(spacing: 8){
                                    Text(emoji)
                                        .font(.system(size: 50))
                                        .frame(width: 100, height: 100)
                                        .background(moodColours[emoji, default: .gray].opacity(0.8))
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    // highlight when pressed
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: emoji == selectedMood ? 3 : 0)
                                        )
                                        .scaleEffect(emoji == selectedMood ? 1.1 : 1.0)
                                        .animation(.easeOut(duration: 0.15), value: selectedMood)
                                    
                                    Text(moodLabels[emoji, default: "mood"])
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                    
                                    
                                }
                                
                            }.disabled(hasSubmittedToday)
                        }
                    }
                    .padding(5)
                    
                    // calender view
                    VStack(spacing: 12) {
                        HStack(spacing: 12){
                            ForEach(pastWeek, id: \.day) { log in
                                let moodColor = moodTextColours[log.moodText ?? ""] ?? .black.opacity(0.3)
                                Button(action: {
                                    triggerHaptic()
                                    if let entry = log.entry {
                                        albumArtURL = nil
                                        albumURL = nil
                                        APIService.searchSongOniTunes(song: entry.title, artist: entry.artist) { result in
                                            DispatchQueue.main.async {
                                                if let result = result {
                                                    self.albumArtURL = URL(string: result.artworkUrl100.replacingOccurrences(of: "100x100bb.jpg", with: "500x500bb.jpg"))
                                                    self.albumURL = URL(string: result.trackViewUrl)
                                                    self.suggestedSong = "\(result.trackName) - \(result.artistName)"
                                                }
                                            }
                                        }
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(moodColor)
                                            .frame(width: 40, height: 40)
                                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                                        
                                        Text(log.day)
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                            .monospacedDigit()
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                }.disabled(log.entry == nil)
                                    .opacity(log.entry == nil ? 0.5 : 1.0)
                            }
                        }
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .shadow(radius: 4)
                    }.padding()
                    
                    // Submit button
                    Button(action :{
                        if let mood = selectedMood, let moodText = moodLabels[mood] {
                            triggerHaptic()
                            isLoading = true
                            // building the hisotry everytime we get a non-duplicate song suggestion, check APIServices
                            APIService.getNonDuplicateSongSuggestion(for: moodText) { result in
                                DispatchQueue.main.async {
                                    isLoading = false
                                    if let suggestion = result {
                                        
                                        APIService.searchSongOniTunes(song: suggestion.title, artist: suggestion.artist) { itunesResult in
                                            DispatchQueue.main.async {
                                                if let itunesResult = itunesResult {
                                                    self.albumArtURL = URL(string: itunesResult.artworkUrl100.replacingOccurrences(of: "100x100bb.jpg", with: "500x500bb.jpg"))
                                                    self.albumURL = URL(string: itunesResult.trackViewUrl)

                                                    // Show **exactly** what we got back from Apple Music:
                                                    let fullSuggestion = "\(itunesResult.trackName) - \(itunesResult.artistName)"
                                                    self.suggestedSong = fullSuggestion
                                                    saveTodayAsCheckedIn()
                                                    let history = SongHistoryManager.loadHistory()
                                                    self.pastWeek = buildPastWeekLog(from: history)
                                                } else {
                                                    // If Apple returned nothing, fall back to the OpenAI suggestion
                                                    self.albumArtURL = nil
                                                    self.albumURL = nil
                                                    self.suggestedSong = "\(suggestion.title) - \(suggestion.artist)"
                                                    saveTodayAsCheckedIn()
                                                    let history = SongHistoryManager.loadHistory()
                                                    self.pastWeek = buildPastWeekLog(from: history)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                    }) {
                        Text(hasSubmittedToday ? "Come back tomorrow!" : "Submit")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .shadow(color: .black, radius: 6)
                            .padding()
                            .background(.black)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal)
                    .disabled(hasSubmittedToday || selectedMood == nil)
                    
                }
                
                // song suggestion card
                ZStack {
                    if let song = suggestedSong {
                        VStack{
                            Spacer()
                            
                            let parts = song.components(separatedBy: " - ")
                            
                            SongSuggestionCard(title: parts.first ?? "Unknown Title",
                                               artist: parts.last ?? "Unknown Artist",
                                               albumArtURL: albumArtURL,
                                               albumURL: albumURL,
                                               onClose: {
                                withAnimation {
                                    suggestedSong = nil
                                }
                            })
                            
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                    }
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: suggestedSong != nil)
                
                // what to show if data is being fetch
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Generating Suggestion...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .fontWeight(.bold)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .settings:
                    SettingsView()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                let history = SongHistoryManager.loadHistory()
                self.pastWeek = buildPastWeekLog(from: history)
                refreshCheckInFlag()
            }
            .onAppear {
                let history = SongHistoryManager.loadHistory()
                self.pastWeek = buildPastWeekLog(from: history)
                refreshCheckInFlag()
            }
        }
        
    }
    
    struct SongSuggestionCard: View {
        let title: String
        let artist: String
        let albumArtURL: URL?
        let albumURL: URL?
        let onClose: () -> Void

        @Environment(\.openURL) private var openURL

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Today's Pick🔥")
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Spacer()

                    Button(action: {
                        onClose()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }

                if let url = albumArtURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: 280)
                                .clipped()
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 12)
                        } else {
                            Color.gray.opacity(0.3)
                                .frame(maxHeight: 280)
                                .cornerRadius(16)
                        }
                    }
                } else {
                    Color.gray.opacity(0.3)
                        .frame(maxHeight: 280)
                        .cornerRadius(16)
                }

                HStack {
                    VStack (alignment: .leading) {
                        Text(title)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .lineLimit(2)

                        Text(artist.uppercased())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    }

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if let url = albumURL {
                            openURL(url)
                        }
                    }) {
                        VStack(alignment: .trailing) {
                            Image(systemName: "arrow.up.right.square.fill")
                                .font(.system(size: 21))
                                .frame(width: 43, height: 43)
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 255/255, green: 100/255, blue: 130/255),  // Very top - lightest pink
                                            Color(red: 254/255, green: 80/255, blue: 100/255),   // Upper middle
                                            Color(red: 252/255, green: 61/255, blue: 85/255),    // Lower middle
                                            Color(red: 250/255, green: 50/255, blue: 70/255)     // Bottom - deepest pink
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .clipShape(Circle())
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    }.disabled(albumURL == nil)
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal)
        }
    }
    
    func saveTodayAsCheckedIn() {
        let today = Date()
        UserDefaults.standard.set(today, forKey: Self.lastCheckInKey)
        hasSubmittedToday = true
    }
    
    private func refreshCheckInFlag() {
        if let last = UserDefaults.standard.object(forKey: Self.lastCheckInKey) as? Date {
            hasSubmittedToday = Calendar.current.isDateInToday(last)
        } else {
            hasSubmittedToday = false
        }
    }
    
    func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
}

// gives "M", "T", "W" etc. from a Date
extension Calendar {
    func shortWeekdaySymbol(for date: Date) -> String {
        let weekday = component(.weekday, from: date) - 1
        return shortWeekdaySymbols[weekday].prefix(1).uppercased()
    }
}

func buildPastWeekLog(from history: [SongSuggestionHistoryEntry]) -> [MoodLog] {
    let uniqueDayLabels = [
        "S", "M", "T", "W", "Th", "F", "Sa"
    ]
    
    let calendar = Calendar.current
    var result: [MoodLog] = []

    for offset in (0..<7).reversed() {
        
        // Get the date for that day (minus by offset)
        guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
        
        // get the day symbol for that date
        let weekdayIndex = calendar.component(.weekday, from: date) - 1 // 0 = Sunday
        let dayLetter = uniqueDayLabels[weekdayIndex]
        
        // Check if there’s a saved suggestion for that day
        if let entry = history.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            let color = moodTextColours[entry.emoji] ?? .black
            result.append(MoodLog(day: dayLetter, moodText: entry.emoji, entry: entry))
        } else {
            result.append(MoodLog(day: dayLetter, moodText: nil, entry: nil))
        }
    }

    return result
}

extension Image {
    func asUIImage() -> UIImage? {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let uiImage = child.value as? UIImage {
                return uiImage
            }
        }
        return nil
    }
}


                       
#Preview {
    ContentView()
}
                       
