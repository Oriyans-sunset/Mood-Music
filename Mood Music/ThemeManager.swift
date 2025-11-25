//
//  ThemeManager.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-08-29.
//

import SwiftUI
import RevenueCat

// MARK: - Theme Model
struct AppTheme: Identifiable {
    let id: String
    let name: String
    let lightGradient: [Color]
    let darkGradient: [Color]
    let calendarStyle: CalendarStyle
    let isPremium: Bool
    let calendarBorderColor: Color?
    let calendarBorderWidth: CGFloat
    let calendarTextFont: Font
    let calendarTextColor: Color
    let calendarGlow: Bool
    let buttonGradientLight: [Color]
    let buttonGradientDark: [Color]
    let buttonTextColor: Color
    
    func gradient(for colorScheme: ColorScheme) -> [Color] {
        return colorScheme == .dark ? darkGradient : lightGradient
    }
    
    func buttonGradient(for colorScheme: ColorScheme) -> [Color] {
        return colorScheme == .dark ? buttonGradientDark : buttonGradientLight
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var selectedTheme: AppTheme
    
    init() {
        if let savedID = UserDefaults.standard.string(forKey: "selectedThemeID"),
           let theme = ThemeManager.allThemes.first(where: { $0.id == savedID }) {
            self.selectedTheme = theme
        } else {
            self.selectedTheme = ThemeManager.defaultTheme
        }
    }
    
    func selectTheme(_ theme: AppTheme) {
        selectedTheme = theme
        UserDefaults.standard.set(theme.id, forKey: "selectedThemeID")
    }

    func trySelectTheme(_ theme: AppTheme, completion: @escaping (Bool) -> Void) {
        if theme.isPremium { // DO NOT FORGET TO CHANGE
            self.selectTheme(theme)
            completion(true)
//            Purchases.shared.getCustomerInfo { customerInfo, error in
//                if let customerInfo = customerInfo,
//                   customerInfo.entitlements.all["premium"]?.isActive == true {
//                    DispatchQueue.main.async {
//                        self.selectTheme(theme)
//                        completion(true)
//                    }
//                } else {
//                    completion(false)
//                }
//            }
        } else {
            self.selectTheme(theme)
            completion(true)
        }
    }
    
    // MARK: - Available Themes
    static let defaultTheme = AppTheme(
        id: "default",
        name: "Default",
        lightGradient: [Color.mint.opacity(0.6), Color.pink.opacity(0.4)],
        darkGradient: [Color.mint.opacity(0.7), Color.black.opacity(0.1)],
        calendarStyle: .circle,
        isPremium: false,
        calendarBorderColor: nil,
        calendarBorderWidth: 0,
        calendarTextFont: .callout,
        calendarTextColor: .white,
        calendarGlow: false,
        buttonGradientLight: [Color.blue.opacity(0.9), Color.teal.opacity(0.9)],
        buttonGradientDark: [Color.indigo.opacity(0.9), Color.mint.opacity(0.9)],
        buttonTextColor: .white
    )
    
    static let allThemes: [AppTheme] = [
        defaultTheme,
        AppTheme(
            id: "sunset",
            name: "Sunset ☀️",
            lightGradient: [Color.orange, Color.pink, Color.purple],
            darkGradient: [Color.purple.opacity(0.8), Color.black.opacity(0.9)],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: .purple,
            calendarBorderWidth: 2,
            calendarTextFont: .headline,
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [Color.orange, Color.pink],
            buttonGradientDark: [Color.purple, Color.orange],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "ocean",
            name: "Ocean 🌊",
            lightGradient: [Color.teal, Color.blue, Color.teal],
            darkGradient: [Color.indigo, Color.black.opacity(0.85)],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: .blue,
            calendarBorderWidth: 2,
            calendarTextFont: .system(.body, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [Color.teal, Color.blue],
            buttonGradientDark: [Color.indigo, Color.blue],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "fall",
            name: "Fall 🍁",
            lightGradient: [Color(red: 0.8, green: 0.4, blue: 0.1), Color(red: 0.82, green: 0.7, blue: 0.5), Color(red: 0.45, green: 0.3, blue: 0.1)],
            darkGradient: [Color(red: 0.3, green: 0.15, blue: 0.05), Color(red: 0.6, green: 0.3, blue: 0.0), Color(red: 0.7, green: 0.4, blue: 0.1)],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 0.6, green: 0.3, blue: 0.0),
            calendarBorderWidth: 2,
            calendarTextFont: .headline,
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [Color(red: 0.8, green: 0.4, blue: 0.1), Color(red: 0.6, green: 0.4, blue: 0.2)],
            buttonGradientDark: [Color(red: 0.5, green: 0.2, blue: 0.0), Color(red: 0.7, green: 0.4, blue: 0.1)],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "auroraDawn",
            name: "Aurora Dawn 👾",
            lightGradient: [
                Color(red: 0.98, green: 0.62, blue: 0.58),
                Color(red: 0.99, green: 0.76, blue: 0.63),
                Color(red: 1.00, green: 0.88, blue: 0.69)
            ],
            darkGradient: [
                Color(red: 0.36, green: 0.18, blue: 0.38),
                Color(red: 0.18, green: 0.08, blue: 0.25)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 0.99, green: 0.76, blue: 0.35),
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.98, green: 0.46, blue: 0.48),
                Color(red: 1.00, green: 0.72, blue: 0.40)
            ],
            buttonGradientDark: [
                Color(red: 0.94, green: 0.36, blue: 0.68),
                Color(red: 0.98, green: 0.62, blue: 0.35)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "glacierMint",
            name: "Glacier Mint 🧊",
            lightGradient: [
                Color(red: 0.80, green: 0.94, blue: 0.92),
                Color(red: 0.55, green: 0.82, blue: 0.82)
            ],
            darkGradient: [
                Color(red: 0.08, green: 0.20, blue: 0.28),
                Color(red: 0.02, green: 0.06, blue: 0.12)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 0.42, green: 0.90, blue: 0.92),
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.36, green: 0.74, blue: 0.78),
                Color(red: 0.19, green: 0.56, blue: 0.80)
            ],
            buttonGradientDark: [
                Color(red: 0.24, green: 0.78, blue: 0.82),
                Color(red: 0.16, green: 0.44, blue: 0.84)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "solarFlare",
            name: "Solar Flare 🌄",
            lightGradient: [
                Color(red: 0.98, green: 0.78, blue: 0.38),
                Color(red: 0.99, green: 0.86, blue: 0.62)
            ],
            darkGradient: [
                Color(red: 0.60, green: 0.27, blue: 0.12),
                Color(red: 0.14, green: 0.09, blue: 0.22)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 1.00, green: 0.66, blue: 0.24),
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.98, green: 0.62, blue: 0.24),
                Color(red: 0.91, green: 0.18, blue: 0.51)
            ],
            buttonGradientDark: [
                Color(red: 1.00, green: 0.46, blue: 0.08),
                Color(red: 0.90, green: 0.17, blue: 0.54)
            ],
            buttonTextColor: .white
        )



    ]
}
