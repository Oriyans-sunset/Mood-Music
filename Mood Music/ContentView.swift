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
    
    @AppStorage("preferredMusicProvider") private var preferredMusicProvider: String = "Apple Music"
    @State private var path = NavigationPath()

    @State private var albumArtURL: URL? = nil
    @State private var albumURL: URL? = nil
    
    @State private var isLoading: Bool = false
    
    @State private var selectedMood:String? = nil
    @State private var suggestedSong:String? = nil
    @State private var pastWeek: [MoodLog] = [] // calender days colour mapping hardocded for now
    
    // used multiple times so we made it a var
    private static let lastCheckInKey = "lastCheckInDate"
    
    // MARK: - One-time update notice after app update
    private static let lastSeenAppVersionKey = "lastSeenAppVersion"
    @State private var showUpdateSheet: Bool = false

    // Replace with your real TagTrail App Store URL (e.g. https://apps.apple.com/app/id1234567890)
    private let tagTrailURLString: String = "https://apps.apple.com/us/app/tagtrail/id6749494325"
    
    
    @State private var hasSubmittedToday: Bool = {
        if let saved = UserDefaults.standard.object(forKey: lastCheckInKey) as? Date {
            return Calendar.current.isDateInToday(saved)
        }
        return false
    }()
    
    // varible defined for opneing external links
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    //Color.black.opacity(0.1), Color.purple.opacity(0.7)]
    //[Color.blue.opacity(0.7), Color.purple.opacity(0.7), Color.teal.opacity(0.6)]
    
    // MARK: - Update notice helpers
    private func currentAppVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }

    private func checkForUpdateNotice() {
        let current = currentAppVersionString()
        let lastSeen = UserDefaults.standard.string(forKey: Self.lastSeenAppVersionKey)
        if lastSeen != current {
            // First launch after install/update → show once
            showUpdateSheet = true
            // Persist immediately so it never shows again for this version
            UserDefaults.standard.set(current, forKey: Self.lastSeenAppVersionKey)
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack{
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark
                            ? [Color.black.opacity(0.1), Color.purple.opacity(0.7)] // dark mode
                            : [Color.mint.opacity(0.6), Color.pink.opacity(0.4)]  // light mode
                        ),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    ZStack {
                        // Center the heading text
                        Text("How are you feeling today?")
                            .multilineTextAlignment(.center)
                            .font(.custom("Pacifico-Regular", size: 50))
                            .fontWeight(.bold)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                            .foregroundColor(.primary)
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
                                        .foregroundColor(.primary)
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
                    
                    let moodGradientColors: [String: [Color]] = [
                        "😊": [Color.yellow, Color.yellow],
                        "😐": [Color.gray, Color.gray],
                        "😔": [Color.blue, Color.indigo],
                        "🤩": [Color.orange, Color.orange],
                        "🥱": [Color.indigo, Color.purple],
                        "😣": [Color.red, Color.pink]
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
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: moodGradientColors[emoji, default: [Color.gray.opacity(0.6), Color.gray]]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.3)]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: emoji == selectedMood ? 4 : 0
                                                )
                                        )
                                        .scaleEffect(emoji == selectedMood ? 1.1 : 1.0)
                                        .animation(.easeOut(duration: 0.15), value: selectedMood)
                                    
                                    Text(moodLabels[emoji, default: "mood"])
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
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
                                Button(action: { handleCalendarTap(log: log) }) {
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }.padding()
                    
                    // Submit button
                    Button(action: {
                        if let mood = selectedMood, let moodText = moodLabels[mood] {
                            handleSubmit(mood: moodText)
                        }
                    }) {
                        Text(hasSubmittedToday ? "Come back tomorrow!" : "Submit")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: colorScheme == .dark
                                        ? [Color.indigo.opacity(0.9), Color.blue.opacity(0.9)]
                                        : [Color.blue.opacity(0.9), Color.teal.opacity(0.9)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: (colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.2)), radius: 10, x: 0, y: 6)
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
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    
                    ProgressView("Generating Suggestion...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
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
                checkForUpdateNotice()
            }
            .sheet(isPresented: $showUpdateSheet) {
                UpdatePromoSheet(
                    tagTrailURL: URL(string: tagTrailURLString),
                    onClose: { showUpdateSheet = false }
                )
                .presentationDetents([.medium])
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
        @Environment(\.colorScheme) private var colorScheme
        @State private var copiedTitle = false
        @State private var copiedArtist = false

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Today's Pick🔥")
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        onClose()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
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
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                UIPasteboard.general.string = title
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    copiedTitle = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                    withAnimation(.easeOut(duration: 0.2)) { copiedTitle = false }
                                }
                            }) {
                                ZStack {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14))
                                        .opacity(copiedTitle ? 0.0 : 1.0)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.green)
                                        .opacity(copiedTitle ? 1.0 : 0.0)
                                        .scaleEffect(copiedTitle ? 1.1 : 0.8)
                                }
                            }
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: copiedTitle)
                            .accessibilityLabel("Copy to clipboard")
#if swift(>=5.9)
                            .sensoryFeedback(.success, trigger: copiedTitle)
#endif
                        }
                        HStack {
                            Text(artist.uppercased())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                UIPasteboard.general.string = artist
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    copiedArtist = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                    withAnimation(.easeOut(duration: 0.2)) { copiedArtist = false }
                                }
                            }) {
                                ZStack {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                        .opacity(copiedArtist ? 0.0 : 1.0)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                        .opacity(copiedArtist ? 1.0 : 0.0)
                                        .scaleEffect(copiedArtist ? 1.1 : 0.8)
                                }
                            }
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: copiedArtist)
                            .accessibilityLabel("Copy to clipboard")
#if swift(>=5.9)
                            .sensoryFeedback(.success, trigger: copiedArtist)
#endif
                        }
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
            .background(Color(UIColor.secondarySystemBackground))
            .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal)
        }
    }
    
    // Helper function for calendar tap
    private func handleCalendarTap(log: MoodLog) {
        triggerHaptic()
        if let entry = log.entry {
            albumArtURL = nil
            albumURL = nil
            if preferredMusicProvider == "Apple Music" {
                APIService.searchSongOniTunes(song: entry.title, artist: entry.artist) { result in
                    DispatchQueue.main.async {
                        if let result = result {
                            self.albumArtURL = URL(string: result.artworkUrl100.replacingOccurrences(of: "100x100bb.jpg", with: "500x500bb.jpg"))
                            self.albumURL = URL(string: result.trackViewUrl)
                            self.suggestedSong = "\(result.trackName) - \(result.artistName)"
                        }
                    }
                }
            } else {
                // First search iTunes for cleaned title/artist, then search Spotify
                APIService.searchSongOniTunes(song: entry.title, artist: entry.artist) { result in
                    DispatchQueue.main.async {
                        if let result = result {
                            // Use cleaned iTunes result to search Spotify
                            APIService.searchSongOnSpotify(song: result.trackName, artist: result.artistName) { coverURL, spotifyLink in
                                DispatchQueue.main.async {
                                    self.albumArtURL = coverURL != nil ? URL(string: coverURL!) : nil
                                    self.albumURL = spotifyLink != nil ? URL(string: spotifyLink!) : nil
                                    self.suggestedSong = "\(result.trackName) - \(result.artistName)"
                                }
                            }
                        } else {
                            // Fallback: use original entry if iTunes fails
                            APIService.searchSongOnSpotify(song: entry.title, artist: entry.artist) { coverURL, spotifyLink in
                                DispatchQueue.main.async {
                                    self.albumArtURL = coverURL != nil ? URL(string: coverURL!) : nil
                                    self.albumURL = spotifyLink != nil ? URL(string: spotifyLink!) : nil
                                    self.suggestedSong = "\(entry.title) - \(entry.artist)"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Helper function for submit button
    private func handleSubmit(mood: String) {
        triggerHaptic()
        isLoading = true
        // building the hisotry everytime we get a non-duplicate song suggestion, check APIServices
        APIService.getNonDuplicateSongSuggestion(for: mood) { result in
            DispatchQueue.main.async {
                isLoading = false
                if let suggestion = result {
                    if preferredMusicProvider == "Apple Music" {
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
                    } else {
                        // First search iTunes for cleaned title/artist, then search Spotify
                        APIService.searchSongOniTunes(song: suggestion.title, artist: suggestion.artist) { itunesResult in
                            DispatchQueue.main.async {
                                if let itunesResult = itunesResult {
                                    // Use cleaned iTunes result to search Spotify
                                    APIService.searchSongOnSpotify(song: itunesResult.trackName, artist: itunesResult.artistName) { coverURL, spotifyLink in
                                        DispatchQueue.main.async {
                                            self.albumArtURL = coverURL != nil ? URL(string: coverURL!) : nil
                                            self.albumURL = spotifyLink != nil ? URL(string: spotifyLink!) : nil
                                            self.suggestedSong = "\(itunesResult.trackName) - \(itunesResult.artistName)"
                                            saveTodayAsCheckedIn()
                                            let history = SongHistoryManager.loadHistory()
                                            self.pastWeek = buildPastWeekLog(from: history)
                                        }
                                    }
                                } else {
                                    // Fallback: use original suggestion if iTunes fails
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

// MARK: - One-time update dialog content
struct UpdatePromoSheet: View {
    let tagTrailURL: URL?
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Spotify integration is now live 🎉")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("""
                    Navigate to settings to choose between Apple Music or Spotify as your music provider of choice.
                    """)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { onClose() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Close update notes")
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Try my new app: TagTrail📍")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Pin quick notes to places and get reminded when you’re nearby. Great for errands, campus life, and ‘don’t forget this’ moments.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button(action: { onClose() }) {
                    Text("Nice!")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }

                Button(action: {
                    if let url = tagTrailURL { openURL(url) }
                    onClose()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square.fill")
                        Text("TagTrail")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme == .dark
                                ? [Color.indigo.opacity(0.95), Color.blue.opacity(0.9)]
                                : [Color.blue.opacity(0.95), Color.teal.opacity(0.9)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 20)
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
                       
