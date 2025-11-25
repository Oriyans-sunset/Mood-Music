//
//  ExportManager.swift
//  Mood Music
//
//  Created by Codex on 2025-xx-xx.
//

import SwiftUI
import UIKit

struct ExportManager {
    
    static func exportCurrentMonth(history: [SongSuggestionHistoryEntry]) -> URL? {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let range = calendar.range(of: .day, in: .month, for: now) else {
            return nil
        }
        
        let monthName = DateFormatter().monthSymbols[calendar.component(.month, from: now) - 1]
        let yearNumber = calendar.component(.year, from: now)
        let monthTitle = "\(monthName) \(yearNumber)"
        
        let monthlyEntries = history.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }.sorted { $0.date < $1.date }
        
        let entriesByDay: [Date: SongSuggestionHistoryEntry] = monthlyEntries.reduce(into: [:]) { result, entry in
            let day = calendar.startOfDay(for: entry.date)
            result[day] = entry
        }
        
        let countsByMood = Dictionary(grouping: monthlyEntries, by: { $0.emoji }).mapValues { $0.count }
        
        // Prepare PDF renderer
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let fileName = "MoodMusic-\(monthName).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try renderer.writePDF(to: url) { ctx in
                // Cover
                ctx.beginPage()
                drawCover(on: ctx, in: pageRect, monthTitle: monthTitle)
                
                // Calendar
                ctx.beginPage()
                drawCalendar(on: ctx, in: pageRect, monthTitle: monthTitle, range: range, startOfMonth: startOfMonth, entriesByDay: entriesByDay, calendar: calendar)
                
                // Stats + songs
                ctx.beginPage()
                drawStatsAndSongs(on: ctx, in: pageRect, monthTitle: monthTitle, countsByMood: countsByMood, entries: monthlyEntries)
            }
            return url
        } catch {
            print("❌ Failed to write PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - Drawing helpers
    private static func drawCover(on ctx: UIGraphicsPDFRendererContext, in rect: CGRect, monthTitle: String) {
        let title = "Your \(monthTitle)\nMoodMusic Timeline"
        let subtitle = "A keepsake of your moods, moments, and songs."
        
        let background = UIBezierPath(rect: rect)
        UIColor.white.setFill()
        background.fill()
        
        let topBlob = UIBezierPath(ovalIn: CGRect(x: rect.midX - 200, y: -80, width: 420, height: 240))
        UIColor(red: 0.65, green: 0.9, blue: 0.88, alpha: 1.0).setFill()
        topBlob.fill()
        
        let bottomBlob = UIBezierPath(ovalIn: CGRect(x: -120, y: rect.maxY - 260, width: 380, height: 220))
        UIColor(red: 1.0, green: 0.76, blue: 0.86, alpha: 1.0).setFill()
        bottomBlob.fill()
        
        let titleStyle = NSMutableParagraphStyle()
        titleStyle.alignment = .center
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 38, weight: .heavy),
            .foregroundColor: UIColor.black,
            .paragraphStyle: titleStyle
        ]
        
        let subtitleStyle = NSMutableParagraphStyle()
        subtitleStyle.alignment = .center
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: subtitleStyle
        ]
        
        title.draw(in: CGRect(x: 60, y: rect.midY - 120, width: rect.width - 120, height: 200), withAttributes: titleAttributes)
        subtitle.draw(in: CGRect(x: 80, y: rect.midY + 40, width: rect.width - 160, height: 80), withAttributes: subtitleAttributes)
    }
    
    private static func drawCalendar(on ctx: UIGraphicsPDFRendererContext,
                                     in rect: CGRect,
                                     monthTitle: String,
                                     range: Range<Int>,
                                     startOfMonth: Date,
                                     entriesByDay: [Date: SongSuggestionHistoryEntry],
                                     calendar: Calendar) {
        let margin: CGFloat = 40
        let title = "Mood Calendar"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .bold),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph
        ]
        title.draw(at: CGPoint(x: margin, y: margin), withAttributes: titleAttributes)
        
        let subtitle = monthTitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        subtitle.draw(at: CGPoint(x: margin, y: margin + 34), withAttributes: subtitleAttributes)
        
        let gridTop = margin + 70
        let availableWidth = rect.width - (margin * 2)
        let cellWidth = (availableWidth - (6 * 6)) / 7 // 6 gaps of 6pt
        let cellHeight = cellWidth
        
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let weekdayStyle = NSMutableParagraphStyle()
        weekdayStyle.alignment = .center
        for (index, symbol) in weekdaySymbols.enumerated() {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: weekdayStyle
            ]
            let x = margin + CGFloat(index) * cellWidth
            let y = gridTop
            let abbrev = String(symbol.uppercased().prefix(2))
            abbrev.draw(in: CGRect(x: x, y: y, width: cellWidth, height: 16), withAttributes: attributes)
        }
        
        let firstWeekdayIndex = calendar.component(.weekday, from: startOfMonth) - calendar.firstWeekday
        let normalizedFirstWeekday = (firstWeekdayIndex + 7) % 7
        
        let dayNumberAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.black,
            .paragraphStyle: weekdayStyle
        ]
        
        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { continue }
            let position = day + normalizedFirstWeekday
            let row = (position) / 7
            let column = position % 7
            
            let x = margin + CGFloat(column) * (cellWidth + 6)
            let y = gridTop + 20 + CGFloat(row) * (cellHeight + 12)
            let cellRect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
            
            let dayPath = UIBezierPath(roundedRect: cellRect, cornerRadius: 12)
            UIColor(white: 0.95, alpha: 1.0).setFill()
            dayPath.fill()
            
            let borderPath = UIBezierPath(roundedRect: cellRect, cornerRadius: 12)
            UIColor.lightGray.withAlphaComponent(0.4).setStroke()
            borderPath.lineWidth = 0.7
            borderPath.stroke()
            
            let dayString = "\(day)"
            dayString.draw(in: CGRect(x: x, y: y + 6, width: cellWidth, height: 18), withAttributes: dayNumberAttributes)
            
            if let entry = entriesByDay[calendar.startOfDay(for: date)] {
                let color = UIColor(moodTextColours[entry.emoji] ?? .gray)
                let circleSize: CGFloat = 20
                let circleRect = CGRect(x: x + (cellWidth - circleSize) / 2, y: y + (cellHeight / 2) - (circleSize / 2), width: circleSize, height: circleSize)
                let circlePath = UIBezierPath(ovalIn: circleRect)
                color.setFill()
                circlePath.fill()
            }
        }
    }
    
    private static func drawStatsAndSongs(on ctx: UIGraphicsPDFRendererContext,
                                          in rect: CGRect,
                                          monthTitle: String,
                                          countsByMood: [String: Int],
                                          entries: [SongSuggestionHistoryEntry]) {
        let margin: CGFloat = 36
        let headerStyle = NSMutableParagraphStyle()
        headerStyle.alignment = .left
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black,
            .paragraphStyle: headerStyle
        ]
        
        "Vibe Recap".draw(at: CGPoint(x: margin, y: margin), withAttributes: headerAttributes)
        
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        monthTitle.draw(at: CGPoint(x: margin, y: margin + 28), withAttributes: subtitleAttributes)
        
        let statsTop: CGFloat = margin + 60
        let columnWidth = (rect.width - margin * 2 - 12) / 2
        
        // Stats column
        var statsY = statsTop
        let statTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        "Mood Stats".draw(at: CGPoint(x: margin, y: statsY), withAttributes: statTitleAttributes)
        statsY += 28
        
        if countsByMood.isEmpty {
            let emptyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            "No moods logged yet this month.".draw(at: CGPoint(x: margin, y: statsY), withAttributes: emptyAttributes)
        } else {
            for (moodText, count) in countsByMood.sorted(by: { $0.value > $1.value }) {
                let emojiIcon = emoji(for: moodText)
                let line = "\(emojiIcon) \(moodText): \(count) day\(count == 1 ? "" : "s")"
                let lineAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
                line.draw(at: CGPoint(x: margin, y: statsY), withAttributes: lineAttributes)
                statsY += 22
            }
        }
        
        // Songs column
        var songsY = statsTop
        let songHeaderX = margin + columnWidth + 12
        "Songs".draw(at: CGPoint(x: songHeaderX, y: songsY), withAttributes: statTitleAttributes)
        songsY += 28
        
        if entries.isEmpty {
            let emptyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            "No songs to show yet.".draw(at: CGPoint(x: songHeaderX, y: songsY), withAttributes: emptyAttributes)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            
            for entry in entries {
                let emojiIcon = emoji(for: entry.emoji)
                let dateString = dateFormatter.string(from: entry.date)
                let line = "\(dateString)  \(emojiIcon)  \(entry.title) — \(entry.artist)"
                let lineAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
                line.draw(in: CGRect(x: songHeaderX, y: songsY, width: columnWidth, height: 24), withAttributes: lineAttributes)
                songsY += 20
                
                if songsY > rect.maxY - 60 {
                    break // keep it concise for the page
                }
            }
        }
    }
}
