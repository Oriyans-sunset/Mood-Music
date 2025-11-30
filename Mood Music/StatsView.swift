//
//  StatsView.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-09-02.
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    @State private var cards: [StatCard] = [
//        StatCard(title: "Mood Frequency", type: .comingSoon, icon: "dice"),
//        StatCard(title: "Streaks", type: .comingSoon, icon: "fire"),
//        StatCard(title: "Weekly Mood Balance", type: .comingSoon, icon: "jukebox"),
//        StatCard(title: "Day of Week", type: .comingSoon, icon: "jukebox"),
        StatCard(title: "More Absolute Fire Stuff...", type: .comingSoon, icon: "fire"),
        StatCard(title: "Month Mood Logs", type: .calendar, icon: "calender")
    ]
    
    @State private var selectedHistoryEntry: SongSuggestionHistoryEntry?
    @State private var showSongCard = false
    @State private var albumArtURL: URL?
    @State private var albumURL: URL?
    @State private var suggestedSong: String?
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var exportError: String?
    @State private var isExporting = false
    
    @AppStorage("preferredMusicProvider") private var preferredMusicProvider: String = "Spotify"

    var pastMonthLogs: [MoodLog] {
        buildPastLog(from: SongHistoryManager.loadHistory(), daysBack: 30)
    }

    var body: some View {
        let themeColors = themeManager.selectedTheme.gradient(for: colorScheme)
        
        ZStack {
            Circle()
                .fill(themeColors.first?.opacity(0.7) ?? .gray.opacity(0.3))
                .blur(radius: 120)
                .offset(x: -150, y: -200)

            Circle()
                .fill(themeColors.last?.opacity(0.7) ?? .gray.opacity(0.3))
                .blur(radius: 150)
                .offset(x: 200, y: 250)
            ForEach(cards.indices, id: \.self) { index in
                StatCardView(card: cards[index], moodLogs: pastMonthLogs, preferredMusicProvider: preferredMusicProvider,
                             albumArtURL: $albumArtURL,
                             albumURL: $albumURL,
                             suggestedSong: $suggestedSong)
                    .offset(x: 0, y: CGFloat(index) * 5) // stacked look
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if abs(value.translation.width) > 100 {
                                    withAnimation {
                                        let card = cards.removeFirst()
                                        cards.append(card)
                                    }
                                }
                            }
                    )
            }
            // Overlay SongSuggestionCard if suggestedSong is set
            if let song = suggestedSong {
                VStack {
                    Spacer()
                    let parts = song.components(separatedBy: " - ")
                    SongSuggestionCard(
                        title: parts.first ?? "Unknown Title",
                        artist: parts.last ?? "Unknown Artist",
                        albumArtURL: albumArtURL,
                        albumURL: albumURL,
                        onClose: {
                            withAnimation {
                                suggestedSong = nil
                            }
                        }
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: suggestedSong != nil)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    generateExport()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .disabled(isExporting)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Could not export PDF", isPresented: Binding(get: { exportError != nil }, set: { _ in exportError = nil })) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "Unknown error")
        }
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Building your PDF...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }
}

struct StatCardView: View {
    let card: StatCard
    let moodLogs: [MoodLog]
    
    let preferredMusicProvider: String
        @Binding var albumArtURL: URL?
        @Binding var albumURL: URL?
        @Binding var suggestedSong: String?

    var body: some View {
        VStack {
            Image(card.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
            
            Text(card.title)
                .font(.headline)
                .padding()
            if card.type == .calendar {
                let dates = daysInMonth()
                    let columns = Array(repeating: GridItem(.flexible()), count: 7)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(dates, id: \.self) { date in
                            if let log = moodLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                                Button(action: {
                                    handleCalendarTap(
                                        log: log,
                                        preferredMusicProvider: preferredMusicProvider,
                                        albumArtURL: $albumArtURL,
                                        albumURL: $albumURL,
                                        suggestedSong: $suggestedSong
                                    )
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(moodTextColours[log.moodText ?? ""] ?? .gray.opacity(0.3))
                                            .frame(width: 28, height: 28)
                                        Text("\(Calendar.current.component(.day, from: date))")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.primary)
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 28, height: 28)
                            }
                        }
                    }
                    .padding() // your 30-day mood grid
            } else {
                Text("Coming Soon")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 8)
        .padding()
    }
}

func daysInMonth() -> [Date] {
    let calendar = Calendar.current
    let today = Date()
    let range = calendar.range(of: .day, in: .month, for: today)!

    let components = calendar.dateComponents([.year, .month], from: today)
    let startOfMonth = calendar.date(from: components)!

    return range.compactMap { day -> Date? in
        calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
    }
}

struct StatCard: Identifiable {
    let id = UUID()
    let title: String
    let type: StatType
    let icon: String
}

enum StatType {
    case calendar   // real implementation now
    case comingSoon // placeholder cards
}

// MARK: - Export
extension StatsView {
    private func generateExport() {
        guard !isExporting else { return }
        isExporting = true
        exportError = nil
        let history = SongHistoryManager.loadHistory()
        DispatchQueue.global(qos: .userInitiated).async {
            let url = ExportManager.exportCurrentMonth(history: history)
            DispatchQueue.main.async {
                isExporting = false
                if let url = url {
                    exportURL = url
                    showShareSheet = true
                } else {
                    exportError = "Something went wrong while building your PDF. Please try again."
                }
            }
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(ThemeManager())
}
