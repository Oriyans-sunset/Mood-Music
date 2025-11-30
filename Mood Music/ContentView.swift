//
//  ContentView.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-23.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

enum Route: Hashable {
    case settings
    case stats
}

struct ContentView: View {
    
    @AppStorage("preferredMusicProvider") private var preferredMusicProvider: String = "Apple Music"
    
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var path = NavigationPath()

    @State private var albumArtURL: URL? = nil
    @State private var albumURL: URL? = nil
    
    @State private var surpriseAlbumArtURL: URL? = nil
    @State private var surpriseAlbumURL: URL? = nil

    @State private var loadingMessage: String? = nil
    
    @State private var selectedMood:String? = nil
    @State private var suggestedSong:String? = nil
    @State private var surpriseSong:String? = nil
    @State private var pastWeek: [MoodLog] = [] // calender days colour mapping hardocded for now
    
    @State private var lastMoodText: String? = nil
    @State private var mainSuggestion: SongSuggestion? = nil
    
    @State private var showPaywall: Bool = false
    @State private var currentOffering: RevenueCat.Offering?
    @State private var isFetchingOffering: Bool = false
    @State private var pendingPremiumAction: PendingPremiumAction?
    @State private var paywallError: String?
    
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    gradient: Gradient(colors: themeManager.selectedTheme.gradient(for: colorScheme)),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                FestiveGarlandOverlay()
                if !reduceMotion {
                    FestiveSnowOverlay(colorScheme: colorScheme)
                        .allowsHitTesting(false)
                }
                
                VStack(spacing: 40) {
                    ZStack {
                        // Center the heading text
                        Text("How are you feeling today?🎄")
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
                                Button(action: {
                                    handlePremiumAction(.openStats) {
                                        path.append(Route.stats)
                                    }
                                }) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                                .padding(.leading, 16)
                                .padding(.top, 12)
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
                                        .font(.system(size: 50, design: .rounded))
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
                        
                            HStack(spacing: 0) {
                                ForEach(pastWeek, id: \.date) { log in
                                    let moodColor = moodTextColours[log.moodText ?? ""] ?? .black.opacity(0.3)
                                    Button(action: {
                                        mainSuggestion = nil
                                        lastMoodText = nil
                                        resetSurpriseState()
                                        handleCalendarTap(
                                            log: log,
                                            preferredMusicProvider: preferredMusicProvider,
                                            albumArtURL: $albumArtURL,
                                            albumURL: $albumURL,
                                            suggestedSong: $suggestedSong
                                        )
                                    }) {
                                        ZStack {
                                            CalendarDayView(
                                                day: log.day,
                                                color: moodColor,
                                                style: themeManager.selectedTheme.calendarStyle,
                                                borderColor: themeManager.selectedTheme.calendarBorderColor,
                                                borderWidth: themeManager.selectedTheme.calendarBorderWidth,
                                                textFont: themeManager.selectedTheme.calendarTextFont,
                                                textColor: themeManager.selectedTheme.calendarTextColor,
                                                glow: themeManager.selectedTheme.calendarGlow
                                            )
                                        }
                                        .frame(width: 50) // fixed width keeps layout consistent
                                    }
                                    .disabled(log.entry == nil)
                                    .opacity(log.entry == nil ? 0.5 : 1.0)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            
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
                    }
                    
                    // Submit button
                    Button(action: {
                        if let mood = selectedMood, let moodText = moodLabels[mood] {
                            handleSubmit(mood: moodText)
                        }
                    }) {
                        Text(hasSubmittedToday ? "Come back tomorrow!" : "Submit")
                            .font(.system(size: 20, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedTheme.buttonTextColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: themeManager.selectedTheme.buttonGradient(for: colorScheme)),
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
                    if suggestedSong != nil || surpriseSong != nil {
                        VStack(spacing: 14){
                            Spacer()
                            
                            if let song = suggestedSong {
                                let parts = song.components(separatedBy: " - ")
                                
                                SongSuggestionCard(title: parts.first ?? "Unknown Title",
                                                   artist: parts.last ?? "Unknown Artist",
                                                   albumArtURL: albumArtURL,
                                                   albumURL: albumURL,
                                                   onClose: {
                                    withAnimation {
                                        suggestedSong = nil
                                        mainSuggestion = nil
                                        lastMoodText = nil
                                        resetSurpriseState()
                                    }
                                })

                            if canRequestSurprise {
                                Button(action: {
                                    handlePremiumAction(.surprise) {
                                        launchSurpriseFlow()
                                    }
                                }) {
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: "die.face.5.fill")
                                                .font(.system(size: 22, weight: .semibold))
                                                .padding(10)
                                                .background(Color.white.opacity(0.2))
                                                .clipShape(Circle())
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Feeling adventurous? 🎲 Surprise Me")
                                                    .font(.headline)
                                                Text("We'll spin up a bonus track near your vibe.")
                                                    .font(.footnote)
                                                    .foregroundColor(themeManager.selectedTheme.buttonTextColor.opacity(0.85))
                                            }
                                            Spacer()
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 18, weight: .semibold))
                                        }
                                        .foregroundColor(themeManager.selectedTheme.buttonTextColor)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: themeManager.selectedTheme.buttonGradient(for: colorScheme)),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(18)
                                        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
                                    }
                                    .padding(.horizontal)
                                    .disabled(loadingMessage != nil)
                                }
                            }

                            if let surprise = surpriseSong {
                                let bonusParts = surprise.components(separatedBy: " - ")
                                SongSuggestionCard(headline: "Surprise Pick 🎲",
                                                   title: bonusParts.first ?? "Unknown Title",
                                                   artist: bonusParts.last ?? "Unknown Artist",
                                                   albumArtURL: surpriseAlbumArtURL,
                                                   albumURL: surpriseAlbumURL,
                                                   onClose: {
                                    withAnimation {
                                        resetSurpriseState()
                                    }
                                })
                            }
                            
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                    }
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: (suggestedSong != nil || surpriseSong != nil))
                
                // what to show if data is being fetch
                if let loadingMessage {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    
                    ProgressView(loadingMessage)
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
                case .stats:
                    StatsView()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                let history = SongHistoryManager.loadHistory()
                self.pastWeek = buildPastLog(from: history, daysBack: 7)
                refreshCheckInFlag()
            }
            .onAppear {
                SongHistoryManager.migrateRawEntries {
                    let history = SongHistoryManager.loadHistory()
                    self.pastWeek = buildPastLog(from: history, daysBack: 7)
                    refreshCheckInFlag()
                    checkForUpdateNotice()
                }
            }
            .sheet(isPresented: $showUpdateSheet) {
                UpdatePromoSheet(
                    tagTrailURL: URL(string: tagTrailURLString),
                    onClose: { showUpdateSheet = false }
                )
                .presentationDetents([.fraction(0.9), .large])
            }
            .sheet(isPresented: $showPaywall) {
                if let offering = currentOffering {
                    if offering.availablePackages.isEmpty {
                        VStack(spacing: 12) {
                            Text("Purchases unavailable right now.")
                                .font(.headline)
                            Text("No purchase packages are currently available. Please try again later.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Close") {
                                showPaywall = false
                                paywallError = "No purchase options available right now. Please try again later."
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else {
                        PaywallView(offering: offering)
                            .onPurchaseCompleted { customerInfo in
                                print("RC purchase entitlements - all: \(customerInfo.entitlements.all.keys), active: \(customerInfo.entitlements.active.keys)")
                                let isUnlocked = ThemeManager.premiumActive(from: customerInfo)
                                themeManager.isPremiumUnlocked = isUnlocked
                                if isUnlocked {
                                    showPaywall = false
                                }
                            }
                            .onRestoreCompleted { customerInfo in
                                print("RC restore entitlements - all: \(customerInfo.entitlements.all.keys), active: \(customerInfo.entitlements.active.keys)")
                                let isUnlocked = ThemeManager.premiumActive(from: customerInfo)
                                themeManager.isPremiumUnlocked = isUnlocked
                                if isUnlocked {
                                    showPaywall = false
                                }
                            }
                            .onDisappear {
                                refreshPremiumStateAndRunPending()
                            }
                    }
                } else {
                    Text("Loading...")
                        .onAppear { fetchOfferingsIfNeeded() }
                }
            }
            .alert("Paywall unavailable", isPresented: Binding(get: { paywallError != nil }, set: { _ in paywallError = nil })) {
                Button("OK", role: .cancel) { paywallError = nil }
            } message: {
                Text(paywallError ?? "Something went wrong. Please try again.")
            }
        }
        
    }
    // Suggestion helpers
    private var canRequestSurprise: Bool {
        mainSuggestion != nil && lastMoodText != nil
    }

    private func handleSubmit(mood: String) {
        triggerHaptic()
        resetSurpriseState()
        loadingMessage = "Generating Suggestion..."
        APIService.getNonDuplicateSongSuggestion(for: mood) { result in
            guard let suggestion = result else {
                DispatchQueue.main.async {
                    loadingMessage = nil
                }
                return
            }
            
            resolveSuggestionForDisplay(suggestion) { resolvedSuggestion, displayText, artURL, linkURL in
                albumArtURL = artURL
                albumURL = linkURL
                suggestedSong = displayText
                mainSuggestion = resolvedSuggestion
                lastMoodText = mood
                saveTodayAsCheckedIn()
                let history = SongHistoryManager.loadHistory()
                pastWeek = buildPastLog(from: history, daysBack: 7)
                loadingMessage = nil
            }
        }
    }

    private func fetchSurpriseSong() {
        guard let mood = lastMoodText,
              let primary = mainSuggestion else { return }
        triggerHaptic()
        loadingMessage = "Rolling the dice..."
        APIService.getSurpriseSongSuggestion(for: mood, avoiding: primary) { result in
            guard let bonusSuggestion = result else {
                DispatchQueue.main.async {
                    loadingMessage = nil
                }
                return
            }
            
            resolveSuggestionForDisplay(bonusSuggestion) { _, displayText, artURL, linkURL in
                surpriseAlbumArtURL = artURL
                surpriseAlbumURL = linkURL
                surpriseSong = displayText
                loadingMessage = nil
            }
        }
    }

    private func launchSurpriseFlow() {
        guard canRequestSurprise else { return }
        // Let the primary card dismiss before presenting the surprise card.
        withAnimation {
            suggestedSong = nil
            albumArtURL = nil
            albumURL = nil
        }
        let delay: DispatchTimeInterval = .milliseconds(320)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            fetchSurpriseSong()
        }
    }

    private func handlePremiumAction(_ action: PendingPremiumAction, perform: @escaping () -> Void) {
        if themeManager.isPremiumUnlocked {
            perform()
        } else {
            pendingPremiumAction = action
            showPaywall = true
            if currentOffering == nil {
                fetchOfferingsIfNeeded()
            }
        }
    }

    private func refreshPremiumStateAndRunPending() {
        themeManager.refreshEntitlements {
            guard themeManager.isPremiumUnlocked, let pending = pendingPremiumAction else {
                pendingPremiumAction = nil
                return
            }
            pendingPremiumAction = nil
            switch pending {
            case .openStats:
                path.append(Route.stats)
            case .surprise:
                launchSurpriseFlow()
            }
        }
    }

    private func fetchOfferingsIfNeeded() {
        guard !isFetchingOffering else { return }
        isFetchingOffering = true
        Purchases.shared.getOfferings { offerings, error in
            DispatchQueue.main.async {
                isFetchingOffering = false
                if let offering = offerings?.current {
                    if offering.availablePackages.isEmpty {
                        currentOffering = nil
                        paywallError = "No purchase options available right now. Please try again later."
                        showPaywall = false
                    } else {
                        currentOffering = offering
                    }
                } else if let error = error {
                    paywallError = error.localizedDescription
                } else {
                    paywallError = "Unable to load paywall right now."
                }
            }
        }
    }

    enum PendingPremiumAction {
        case openStats
        case surprise
    }

    private func resolveSuggestionForDisplay(
        _ suggestion: SongSuggestion,
        completion: @escaping (SongSuggestion, String, URL?, URL?) -> Void
    ) {
        func finish(_ resolved: SongSuggestion, artURL: URL?, linkURL: URL?) {
            let displayText = "\(resolved.title) - \(resolved.artist)"
            DispatchQueue.main.async {
                completion(resolved, displayText, artURL, linkURL)
            }
        }
        
        if preferredMusicProvider == "Apple Music" {
            APIService.searchSongOniTunes(song: suggestion.title, artist: suggestion.artist) { itunesResult in
                if let itunesResult = itunesResult {
                    let corrected = SongSuggestion(title: itunesResult.trackName, artist: itunesResult.artistName)
                    let artURL = URL(string: itunesResult.artworkUrl100.replacingOccurrences(of: "100x100bb.jpg", with: "500x500bb.jpg"))
                    let trackURL = URL(string: itunesResult.trackViewUrl)
                    finish(corrected, artURL: artURL, linkURL: trackURL)
                } else {
                    finish(suggestion, artURL: nil, linkURL: nil)
                }
            }
        } else {
            APIService.searchSongOniTunes(song: suggestion.title, artist: suggestion.artist) { itunesResult in
                if let itunesResult = itunesResult {
                    let corrected = SongSuggestion(title: itunesResult.trackName, artist: itunesResult.artistName)
                    APIService.searchSongOnSpotify(song: corrected.title, artist: corrected.artist) { coverURL, spotifyLink in
                        let artURL = coverURL.flatMap { URL(string: $0) }
                        let linkURL = spotifyLink.flatMap { URL(string: $0) }
                        finish(corrected, artURL: artURL, linkURL: linkURL)
                    }
                } else {
                    APIService.searchSongOnSpotify(song: suggestion.title, artist: suggestion.artist) { coverURL, spotifyLink in
                        let artURL = coverURL.flatMap { URL(string: $0) }
                        let linkURL = spotifyLink.flatMap { URL(string: $0) }
                        finish(suggestion, artURL: artURL, linkURL: linkURL)
                    }
                }
            }
        }
    }

    private func resetSurpriseState() {
        surpriseSong = nil
        surpriseAlbumArtURL = nil
        surpriseAlbumURL = nil
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

// MARK: - Festive decorations
private struct FestiveGarlandOverlay: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color(red: 0.12, green: 0.35, blue: 0.22).opacity(0.28),
                    .clear
                ],
                center: .topLeading,
                startRadius: 10,
                endRadius: 260
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color(red: 0.78, green: 0.60, blue: 0.18).opacity(0.20),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 220
            )
            .ignoresSafeArea()
        }
    }
}

private struct FestiveSnowOverlay: View {
    let colorScheme: ColorScheme
    @State private var drift = false
    private let snowflakes: [Snowflake] = (0..<14).map { _ in Snowflake() }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<snowflakes.count, id: \.self) { index in
                    let flake = snowflakes[index]
                    Circle()
                        .fill(Color.white.opacity(colorScheme == .light ? 0.38 : 0.24))
                        .frame(width: flake.size, height: flake.size)
                        .position(x: flake.x(in: geo.size),
                                  y: flake.y(in: geo.size, drift: drift))
                        .blur(radius: flake.blur)
                        .animation(
                            Animation.linear(duration: flake.duration)
                                .repeatForever(autoreverses: false)
                                .delay(flake.delay),
                            value: drift
                        )
                }
            }
            .onAppear { drift = true }
        }
        .allowsHitTesting(false)
    }
    
    private struct Snowflake {
        let seedX = Double.random(in: 0...1)
        let seedY = Double.random(in: 0...1)
        let speed = Double.random(in: 0.08...0.16)
        let size = Double.random(in: 2.5...5.5)
        let blur = Double.random(in: 0...1.5)
        let delay = Double.random(in: 0...2.0)
        
        var duration: Double { 10 / speed }
        
        func x(in size: CGSize) -> CGFloat {
            CGFloat(seedX) * size.width
        }
        
        func y(in size: CGSize, drift: Bool) -> CGFloat {
            let base = CGFloat(seedY) * size.height
            return drift ? base + size.height * 0.15 : base
        }
    }
}

struct SongSuggestionCard: View {
    let headline: String
    let title: String
    let artist: String
    let albumArtURL: URL?
    let albumURL: URL?
    let onClose: () -> Void

    init(
        headline: String = "Today's Pick🔥",
        title: String,
        artist: String,
        albumArtURL: URL?,
        albumURL: URL?,
        onClose: @escaping () -> Void
    ) {
        self.headline = headline
        self.title = title
        self.artist = artist
        self.albumArtURL = albumArtURL
        self.albumURL = albumURL
        self.onClose = onClose
    }

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @State private var copiedTitle = false
    @State private var copiedArtist = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(headline)
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


enum CalendarStyle {
    case circle
    case pill
    case square
}

struct CalendarDayView: View {
    let day: String
    let color: Color
    let style: CalendarStyle
    // Customization parameters
    var borderColor: Color? = nil
    var borderWidth: CGFloat = 0
    var textFont: Font = .callout
    var textColor: Color = .white
    var glow: Bool = false
    
    var body: some View {
        Group {
            switch style {
            case .circle:
                Circle()
                    .fill(color)
                    .overlay(
                        Circle()
                            .stroke(borderColor ?? .white, lineWidth: borderWidth)
                            .opacity(borderWidth > 0 ? 1 : 0)
                    )
                    .overlay(
                        Text(day)
                            .font(textFont)
                            .fontWeight(.semibold)
                            .foregroundColor(textColor)
                    )
                    .frame(width: 40, height: 40)
            case .pill:
                RoundedRectangle(cornerRadius: 20)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(borderColor ?? .white, lineWidth: borderWidth)
                            .opacity(borderWidth > 0 ? 1 : 0)
                    )
                    .overlay(
                        Text(day)
                            .font(textFont)
                            .fontWeight(.semibold)
                            .foregroundColor(textColor)
                    )
                    .frame(width: 55, height: 40)
            case .square:
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(borderColor ?? .white, lineWidth: borderWidth)
                            .opacity(borderWidth > 0 ? 1 : 0)
                    )
                    .overlay(
                        Text(day)
                            .font(textFont)
                            .fontWeight(.semibold)
                            .foregroundColor(textColor)
                    )
                    .frame(width: 40, height: 40)
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
        .modifier(GlowShadowModifier(glow: glow, borderColor: borderColor))
    }
}

// Helper modifier for glow shadow
private struct GlowShadowModifier: ViewModifier {
    let glow: Bool
    let borderColor: Color?
    func body(content: Content) -> some View {
        if glow {
            content
                .shadow(color: (borderColor ?? .white).opacity(0.8), radius: 6)
        } else {
            content
        }
    }
}

// gives "M", "T", "W" etc. from a Date
extension Calendar {
    func shortWeekdaySymbol(for date: Date) -> String {
        let weekday = component(.weekday, from: date) - 1
        return shortWeekdaySymbols[weekday].prefix(1).uppercased()
    }
}

func buildPastLog(from history: [SongSuggestionHistoryEntry], daysBack: Int) -> [MoodLog] {
    let uniqueDayLabels = [
        "S", "M", "T", "W", "Th", "F", "Sa"
    ]
    
    let calendar = Calendar.current
    var result: [MoodLog] = []

    for offset in (0..<daysBack).reversed() {
        guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
        
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let dayLetter = uniqueDayLabels[weekdayIndex]
        
        if let entry = history.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            result.append(
                MoodLog(
                    date: date,
                    day: dayLetter,
                    moodText: entry.emoji,
                    entry: entry
                )
            )
        } else {
            result.append(
                MoodLog(
                    date: date,
                    day: dayLetter,
                    moodText: nil,
                    entry: nil
                )
            )
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
        .environmentObject(ThemeManager())
}
                       
